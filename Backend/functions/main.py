# Deploy with `firebase emulators:start --only functions ` in the backend directory

from firebase_functions import https_fn, scheduler_fn
from firebase_admin import initialize_app, storage
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
import asyncio
from rag import *
from miniCPM import *
from gemini import *


load_dotenv(".env")  # Load environment variables from .env file
initialize_app() # Initialize Firebase app

#function to query the model with the image and the user query using RAG
@https_fn.on_call(timeout_sec=180)
def rag_image(req: https_fn.CallableRequest):
    response={}
    messages=req.data.get('query')
    data=req.data.get('data')
    query=messages[-1]["content"]
    [print(i) for i in query] if query is not None else None

    finalPrompt=asyncio.run(ragQuerying(data,query))
    messages[-1]["content"]=finalPrompt
    res=requests.post(URL,json={"query":messages,"data":data,"mime_type":"image/jpeg"}).json()
    response["Description"]=res["output"]
    print(response)
    return response


#function to query the model with the image and the user query
@https_fn.on_call(timeout_sec=120)
def image(req: https_fn.CallableRequest):
    query = req.data.get('query') # Get the user query from the request
    data = req.data.get('data') # Get the image data from the request
    mime_type = req.data.get('mime_type') # Get the mime type of the image from the request
    [print(i) for i in query] if query is not None else None

    # response=imageWithGemini(query=query,data=data,mime_type=mime_type) # Get the response from the gemini model  
    response=imageWithMiniCPM(messages=query,data=data,mime_type=mime_type) # Get the response from the miniCPM model
    print(response)
    return response


#function to query the model with the video and the user query
@https_fn.on_call(timeout_sec=180)
def video(req: https_fn.CallableRequest):
    query = req.data.get('query') # Get the user query from the request
    data = req.data.get('data') # Get the video data from the request
    mime_type = req.data.get('mime_type') # Get the mime type of the video from the request
    [print(i) for i in query] if query is not None else None
    
    # response=videoWithGemini(query=query,data=data,mime_type=mime_type) # Get the response from the gemini model
    response=videoWithMiniCPM(messages=query,data=data,mime_type=mime_type) # Get the response from the miniCPM model
    print(response)
    return response


# Function to delete files older than 12 hours in Firebase Storage
@scheduler_fn.on_schedule(schedule="0 */12 * * *")
def delete_old_files(event: scheduler_fn.ScheduledEvent):
    bucket = storage.bucket()  # Get the default storage bucket
    now = datetime.now(timezone.utc)
    cutoff_time = now - timedelta(hours=12)

    blobs = bucket.list_blobs()

    for blob in blobs:
        if blob.time_created < cutoff_time:
            print(f"Deleting blob: {blob.name}")
            blob.delete()

    print("Deletion of old files complete.")