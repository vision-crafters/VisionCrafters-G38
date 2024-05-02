# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
import vertexai
import google.generativeai as genai
import vertexai.generative_models as vgenai
import json
import os

initialize_app()

@https_fn.on_call()
def image(req: https_fn.CallableRequest):
    GOOGLE_API_KEY=os.environ.get('GOOGLE_API_KEY')
    genai.configure(api_key=GOOGLE_API_KEY)
    model = genai.GenerativeModel('gemini-pro-vision', generation_config={'max_output_tokens': 512})
    query = req.data.get('query')
    if query:
        textPart = query
    else:
        textPart = """Describe the image in detail. Also provide a suitable title for the image. 
        Answer whether there is anything dangerous on a scale of 10 for a visually impaired person in the image. 
        The answer should only contain the key-value {Danger, Title, Description}.VERY IMPORTANT!!! Return only a JSON object"""
    data = req.data.get('data')
    mime_type = req.data.get('mime_type')
    filePart = {
                'mime_type': mime_type,
                'data': data
                }
    response = model.generate_content([textPart, filePart])
    print(response.candidates[0].content.parts[0].text)

    stripResponse = response.candidates[0].content.parts[0].text.strip(' `json')
    print(stripResponse)
    response_dict = json.loads(stripResponse)
    return response_dict

@https_fn.on_call()
def video(req: https_fn.CallableRequest):
    vertexai.init(project='vision-crafters', location='asia-south1')
    model = vgenai.GenerativeModel('gemini-pro-vision', generation_config={'max_output_tokens': 512})
    query = req.data.get('query')
    if query:
        textPart = query
    else:
        textPart = """Describe the video in detail. Also provide a suitable title for the video. 
        Answer whether there is anything dangerous on a scale of 10 for a visually impaired person in the video. 
        The answer should only contain the key-value {Danger, Title, Description}.VERY IMPORTANT!!! Return only a JSON object"""
    data = req.data.get('data')
    mime_type = req.data.get('mime_type')
    filePart = vgenai.Part.from_uri(
            data, mime_type=mime_type
        )
    response = model.generate_content([textPart, filePart])
    stripResponse = response.candidates[0].content.parts[0].text.strip(' `json')
    print(stripResponse)
    response_dict = json.loads(stripResponse)
    return response_dict
