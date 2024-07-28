import os
from dotenv import load_dotenv
import requests
load_dotenv()
URL=os.getenv("API")+"/api/invoke/"


def imageWithMiniCPM(messages:list,data:str,mime_type:str)->dict:
    prompts={
        "Danger":
            '''Answer as a Yes/No. Is there any medium or high-risk hazard in the image that a visually impaired user should be aware of? For example:

                    1. Obstacles on the ground, such as uneven pavement, steps, or debris.
                    2. Fast-moving vehicles, like cars, bicycles, or scooters.
                    3. Open flames or hot surfaces, such as candles, stoves, or bonfires.
                    4. Sharp objects, including knife, broken glass, tools, or exposed nails.
                    5. Slippery surfaces, like wet floors, ice, or oil spills.
                    6. Electrical hazards, such as exposed wires or malfunctioning equipment.
                    7. Falling objects, such as unstable shelves, tree branches, or construction materials.
                    8. Bodies of water, like pools, ponds, or streams.
                    9. Animals, particularly aggressive dogs or wildlife.
                    10. Loud noises that could indicate an approaching hazard, like sirens, alarms, or construction sounds.

            Please respond with 'Yes' or 'No' to indicate if any of these hazards are present in the image. Please only respond with 'Yes' or 'No'.''',
        "Title":'''Provide a suitable title for the image. Give only the title. Examples of the response: 
                    Busy Street with Unmarked Construction Area
                    Cozy Coffee Shop''',
        "Description":"Describe the image in detail, focusing on key elements. Limit your description to 40 to 50 words."
    }

    response={}
    if not mime_type.startswith("image"):
        response["Error"]="Invalid mime type"
        return response
    if not messages:
        for key in prompts:
            if key=="Description" and response["Danger"].lower().startswith("yes"):
                    userPrompt="Describe the image  , highlighting any hazards present. Limit your description to 40 to 50 words."
            else:
                userPrompt=prompts[key]
            reqOBj={"query":[{'role': 'user', 'content': userPrompt}], 'data': data, 'mime_type': mime_type}
            res=requests.post(URL,json=reqOBj).json()
            if "error" in res:
                print(response)
                response["Error"]=res["error"]
                return response
            response[key]=res["output"]
    else:
        reqOBj={"query":messages, 'data': data, 'mime_type': mime_type}
        res=requests.post(URL,json=reqOBj).json()
        if "error" in res:
            print(response)
            response["Error"]=res["error"]
            return response
        response["Description"]=res["output"]
    return response

def videoWithMiniCPM(messages:list,data:str,mime_type:str)->dict:
    prompts={
        "Danger":
            '''Answer as a Yes/No. Is there any medium or high-risk hazard in the video that a visually impaired user should be aware of? For example:

                    1. Obstacles on the ground, such as uneven pavement, steps, or debris.
                    2. Fast-moving vehicles, like cars, bicycles, or scooters.
                    3. Open flames or hot surfaces, such as candles, stoves, or bonfires.
                    4. Sharp objects, including broken glass, tools, or exposed nails.
                    5. Slippery surfaces, like wet floors, ice, or oil spills.
                    6. Electrical hazards, such as exposed wires or malfunctioning equipment.
                    7. Falling objects, such as unstable shelves, tree branches, or construction materials.
                    8. Bodies of water, like pools, ponds, or streams.
                    9. Animals, particularly aggressive dogs or wildlife.
                    10. Loud noises that could indicate an approaching hazard, like sirens, alarms, or construction sounds.

                Please respond with 'Yes' or 'No' to indicate if any of these hazards are present in the image. Please only respond with 'Yes' or 'No'.''',

        "Title":'''Provide a suitable title for the image. Give only the title. Examples of the response: 
                    Busy Street with Unmarked Construction Area
                    Cozy Coffee Shop''',
        "Description":"Describe the video in detail, focusing on key elements. Limit your description to 40 to 50 words."
    }
    response={}
    if not mime_type.startswith("video"):
        response["Error"]="Invalid mime type"
        return response
    
    if not messages:
        for key in prompts:
            if key=="Description" and response["Danger"].lower().startswith("yes"):
                    userPrompt="Describe the video, highlighting any hazards present. Limit your description to 40 to 50 words."
            else:
                userPrompt=prompts[key]
            reqOBj={"query":[{'role': 'user', 'content': userPrompt}], 'data': data, 'mime_type': mime_type}
            res=requests.post(URL,json=reqOBj).json()
            if "error" in res:
                print("Error caught")
                response["Error"]=res["error"]
                return response
            response[key]=res["output"]
    else:
        reqOBj={"query":messages, 'data': data, 'mime_type': mime_type}
        res=requests.post(URL,json=reqOBj).json()
        if "error" in res:
            
            response["Error"]=res["error"]
            return response
        response["Description"]=res["output"]
    return response


