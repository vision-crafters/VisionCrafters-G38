# Deploy with `firebase emulators:start --only functions ` in the backend directory

from firebase_functions import https_fn
from firebase_admin import initialize_app

import asyncio
from rag import rag_querring
from miniCPM import *
from gemini import *

load_dotenv(".env")  # Load environment variables from .env file
initialize_app() # Initialize Firebase app

#function to query the model with the image and the user query using RAG
@https_fn.on_call()
def rag_image(req: https_fn.CallableRequest):
    response={}
    messages=req.data.get('query')
    data=req.data.get('data')
    query=messages[-1]["content"]
    finalPrompt=asyncio.run(rag_querring(data,query))
    messages[-1]["content"]=finalPrompt
    response["Descriptiom"]=requests.post(URL,json={"query":messages,"data":data,"mime_type":"image/jpeg"}).json()
    return response


#function to query the model with the image and the user query
@https_fn.on_call()
def image(req: https_fn.CallableRequest):
    query = req.data.get('query') # Get the user query from the request
    data = req.data.get('data') # Get the image data from the request
    mime_type = req.data.get('mime_type') # Get the mime type of the image from the request

    # response=imageWithGemini(query=query,data=data,mime_type=mime_type) # Get the response from the gemini model  
    response=imageWithMiniCPM(messages=query,data=data,mime_type=mime_type) # Get the response from the miniCPM model

    return response


#function to query the model with the video and the user query
@https_fn.on_call()
def video(req: https_fn.CallableRequest):
    query = req.data.get('query') # Get the user query from the request
    data = req.data.get('data') # Get the video data from the request
    mime_type = req.data.get('mime_type') # Get the mime type of the video from the request
    
    # response=videoWithGemini(query=query,data=data,mime_type=mime_type) # Get the response from the gemini model
    response=videoWithMiniCPM(messages=query,data=data,mime_type=mime_type) # Get the response from the miniCPM model
    print(response)
    return response