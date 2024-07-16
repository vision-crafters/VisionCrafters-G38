from flask import Flask, request, jsonify
from PIL import Image
import base64
from io import BytesIO
import torch
from transformers import AutoModel, AutoTokenizer
from google.cloud import storage
import re
import urllib.parse
import subprocess
import io
import dotenv
import json

# Load environment variables from a .env file
dotenv.load_dotenv()

# Initialize Google Cloud Storage client
storage_client = storage.Client("vision-crafters")

# Function to extract the bucket and path from a GCS URL
def extract_bucket_path(url):
    match = re.search(r'/b/([^/]+)/o/([^?]+)', url)
    if match:
        bucket = match.group(1)
        path = urllib.parse.unquote(match.group(2))
        return bucket, path
    else:
        raise ValueError("Invalid URL format")

# Function to get the indices of keyframes in a video
def get_keyframe_indices(video_path):
    """Use ffprobe to get the indices of keyframes."""
    result = subprocess.run(
        ['ffprobe', '-select_streams', 'v', '-show_frames', '-show_entries', 'frame=pict_type', '-of', 'csv', video_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    lines = result.stdout.split('\n')
    keyframe_indices = []
    for index, line in enumerate(lines):
        parts = line.split(',')
        if len(parts) >= 2 and parts[1] == 'I':
            keyframe_indices.append(index)
    return keyframe_indices

# Function to extract a frame at a specific index from a video
def extract_frame_at_index(video_path, index):
    """Use ffmpeg to extract a frame at a specific index and return it as a PIL Image."""
    process = subprocess.Popen(
        ['ffmpeg', '-vsync', '0', '-i', video_path, '-vf', f'select=eq(n\,{index})', '-frames:v', '1', '-f', 'image2pipe', '-vcodec', 'png', 'pipe:1'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    raw_image = process.stdout.read()
    process.stdout.close()
    process.stderr.close()
    process.wait()
    image = Image.open(io.BytesIO(raw_image))
    return image


def load_model_and_tokenizer():
    global model, tokenizer
    model = AutoModel.from_pretrained('openbmb/MiniCPM-Llama3-V-2_5', trust_remote_code=True, torch_dtype=torch.float16)
    model = model.to(device='cuda')
    tokenizer = AutoTokenizer.from_pretrained('openbmb/MiniCPM-Llama3-V-2_5', trust_remote_code=True)
    model.eval()

load_model_and_tokenizer()

# Initialize Flask app
app = Flask(__name__)
# Function to load the model and tokenizer


def imageinvoke(msgs,image=None)->str:
    if image==None:
        res=model.chat(
            image=None,
            context=None,
            msgs=msgs,
            tokenizer=tokenizer,
            sampling=True,
            temperature=0.7
        )
        return res
    res=model.chat(
            image=image,
            msgs=msgs,
            tokenizer=tokenizer,
            sampling=True,
            temperature=0.7
        )
    return res

def videoInvoke(videopth,messages)->dict:
    response={}
    msgs=[]
    SystemPrompt = "These are sequential frames from a video. Each frame is part of a continuous sequence, so preserve the temporal context. Process these frames as a video, capturing both spatial and temporal dependencies."

    keyframe_indices = get_keyframe_indices(videopth)
    frames = []
    for index in keyframe_indices:
        image = extract_frame_at_index(videopth, index)
        frames.append(image)

    # Resize frames and prepare messages
    temp_msgs = []
    if messages:
        UserPrompt = messages[-1]["content"]
        msgs = messages[0:(len(messages)-1)]
        if SystemPrompt:
            temp_msgs.append(dict(type='text', value=SystemPrompt))
        if isinstance(frames, list):
            for frame in frames:
                resized_image = frame.resize((448, 448))
                temp_msgs.append(dict(type='image', value=resized_image))
        else:
            temp_msgs = [dict(type='image', value=frames)]
        content = []
        for x in temp_msgs:
            if x['type'] == 'text':
                content.append(x['value'])
            elif x['type'] == 'image':
                image = x['value'].convert('RGB')
                content.append(image)
        
        content.append(UserPrompt)
                
        msgs.append({'role': 'user', 'content': content})

        response["output"]=imageinvoke(msgs)
    else:
        response["error"]="No messages provided"
    return response    


# Load the model and tokenizer before the first request

# Home route
@app.route('/', methods=["GET"])
async def home():
    return "Vision Crafters"

# API route to handle image and video processing requests
@app.route('/api/invoke/', methods=['POST'])
async def api():
    try:
        # Parse the incoming JSON request
        data = request.get_json()
        messages = data.get('query', '')
        mime_type = data['mime_type']
        msgs = []
        response={}
        # Handle image processing
        if mime_type.startswith("image"):
            try:
                base64_image = data['data']
                image_data = base64.b64decode(base64_image)
                image_bytes = BytesIO(image_data)
                image = Image.open(image_bytes).convert('RGB')

                if messages:
                    response["output"]=imageinvoke(image=image,msgs=messages)
                else:
                    response["error"]="No messages provided"
                # Generate the response
                return jsonify(response)
            except Exception as e:
                print(e)
                return jsonify({'error': str(e)}), 400

        # Handle video processing
        elif mime_type.startswith("video"):
            try:
                url = data["data"]

                # Extract the bucket and path from the URL
                bucket, path = extract_bucket_path(url)
                bucket = storage_client.bucket(bucket)
                blob = bucket.blob(path)
                blob.download_to_filename("temp.mp4")

                # Extract keyframes from the video
                response=videoInvoke(videopth="temp.mp4",messages=messages)
                return jsonify(response)
            except Exception as e:
                return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 400
