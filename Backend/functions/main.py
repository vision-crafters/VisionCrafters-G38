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
import re
import urllib.parse

initialize_app()


def convert_to_gs_url(url):
    match = re.search(r'/b/([^/]+)/o/([^?]+)', url)
    print(match)
    if match:
        bucket = match.group(1)
        path = urllib.parse.unquote(match.group(2))
        print(path)
        return f"gs://{bucket}/{path}"
    else:
        raise ValueError("Invalid URL format")

@https_fn.on_call()
def image(req: https_fn.CallableRequest):
    GOOGLE_API_KEY=os.environ.get('GOOGLE_API_KEY')
    genai.configure(api_key=GOOGLE_API_KEY)
    model = genai.GenerativeModel('gemini-pro-vision', generation_config={'max_output_tokens': 512})
    query = req.data.get('query')
    if query:
        textPart = query
    else:
        textPart = """
        Describe the image in detail. Also provide a suitable title for the image. 
        Answer whether there is anything dangerous with a 'Yes/No' for a visually impaired person in the image. Only if 'Yes', provide the information regarding the danger.
        The answer should only contain the key-value {Danger, Title, Description}. Return only a JSON object
        
        Examples of the response:
        {
            "Danger": "Yes",
            "Title": "Crowded Street with Unmarked Construction Area",
            "Description": "A busy urban street with a lot of pedestrian and vehicular traffic. There is an unmarked construction area with scattered debris and a partially open manhole in the middle of the sidewalk, posing significant risks to visually impaired individuals."
        }

        {
            "Danger": "No",
            "Title": "Cozy Coffee Shop",
            "Description": "An image capturing the cozy atmosphere of a coffee shop. The interior is warmly lit with soft, ambient lighting. There are comfortable seating arrangements, including plush armchairs and wooden tables. A chalkboard on the wall displays the day's specials, and there is a handwritten sign near the entrance that says 'Welcome to Our Happy Place'. Customers are seen chatting and enjoying their drinks, creating a welcoming and inviting environment."
        }
        """
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
    vertexai.init(project='vision-crafters', location='us-central1')
    model = vgenai.GenerativeModel('gemini-pro-vision', generation_config={'max_output_tokens': 512})
    query = req.data.get('query')
    if query:
        textPart = query
    else:
        textPart = """
        Describe the video in detail. Also provide a suitable title for the video. 
        Answer whether there is anything dangerous with a Yes/No for a visually impaired person in the video. Only if 'Yes', provide the information regarding the danger.
        The answer should only contain the key-value {Danger, Title, Description}.Return only a JSON object!
        
        Examples of the response:
        {
            "Danger": "Yes",
            "Title": "Busy Intersection with Fast-Moving Traffic",
            "Description": "A video showing a busy city intersection with fast-moving vehicles and numerous pedestrians. Traffic signals are changing frequently, and there are no audible signals for visually impaired individuals. The chaotic environment and lack of clear pathways make it extremely dangerous. One pedestrian is seen narrowly avoiding a car, highlighting the high risk involved."
        }

        {
            "Danger": "No",
            "Title": "Quiet Library Reading Room",
            "Description": "A video of a quiet library reading room. The room is spacious and well-lit with rows of bookshelves and comfortable seating areas. A sign on the wall reads 'Please Keep Silence'. There are large windows letting in natural light, and the environment is calm and orderly, making it an ideal place for studying and reading."
        }
        """
    data = req.data.get('data')
    mime_type = req.data.get('mime_type')
    filePart = vgenai.Part.from_uri(convert_to_gs_url(data), mime_type=mime_type)
    print(data)
    print(convert_to_gs_url(data))
    response = model.generate_content([textPart, filePart])
    stripResponse = response.candidates[0].content.parts[0].text.strip(' `json')
    print(stripResponse)
    response_dict = json.loads(stripResponse)
    return response_dict
