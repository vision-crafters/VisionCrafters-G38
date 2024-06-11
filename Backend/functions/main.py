# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
from dotenv import load_dotenv
import vertexai
import google.generativeai as genai
import vertexai.generative_models as vgenai
import json
import os
import re
import urllib.parse

load_dotenv(".env")
initialize_app()
from rag import*


def convert_to_gs_url(url):
    match = re.search(r'/b/([^/]+)/o/([^?]+)', url)
    if match:
        bucket = match.group(1)
        path = urllib.parse.unquote(match.group(2))
        return f"gs://{bucket}/{path}"
    else:
        raise ValueError("Invalid URL format")

@https_fn.on_call()
def image_with_rag(req: https_fn.CallableRequest):
    GOOGLE_API_KEY=os.environ.get('GOOGLE_API_KEY')
    genai.configure(api_key=GOOGLE_API_KEY)
    config = genai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='plain/text')
    
    system_prompt_keyword_fetch='''You are an advanced language model that extracts relevant keywords from user queries. These keywords are used to search relavant data on wikipedia. Follow these guidelines:

    Extract Keywords: Identify and list the most relevant keywords from the user query. Provide the keywords in a comma-separated format.
    Image Consideration: If an image is provided along with the query, ensure that the keywords are appropriate and related to the content of both the query and the image.
    Conciseness: Ensure the keywords are concise and directly related to the main topics or concepts in the query.
    Relevance: Focus on the most important words that capture the essence of the query.
    Examples:
    Query: "Show me the latest trends in AI technology."
    Output: "latest trends, AI technology, trends in AI, artificial intelligence"

    Query with Image: A picture of a Tesla car with the query "Tell me about this."
    Output: "Tesla, electric car, vehicle, automotive technology, Tesla Model"

    Query: "Best practices for remote work productivity."
    Output: "best practices, remote work, productivity, work from home, efficiency"

    Query with Image: An image of a beach with the query "What activities can I do here?"
    Output: "beach activities, outdoor recreation, water sports, beach games, seaside activities"
    Also dont keep  /n at the end of the output'''
    # print(system_prompt_keyword_fetch)
    model = genai.GenerativeModel('gemini-1.5-flash',system_instruction=system_prompt_keyword_fetch)
    llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash",temperature=0.6, response_mime_type='plain/text')
    # key_word_prompt = ChatPromptTemplate.from_messages(
    #     [
    #         ("system", system_prompt_keyword_fetch),
    #         ("human", [{filepart},{textpart}]),
    #     ]
    # )
    # keywordChain=LLMChain(llm=llm,prompt=key_word_prompt)
    textpart = req.data.get('query')
    querry={"input":textpart}
    data = req.data.get('data')
    mime_type = req.data.get('mime_type')
    print('\n\nData:\r',mime_type,'\n\n')
    filePart = {
                'mime_type': mime_type,
                'data': data
                }
    
    res=model.generate_content([textpart, filePart], generation_config=config)
    print("\n\nresponse:\n",res.candidates[0].content.parts[0].text,"\n\n")
    # retriever = sequential_chain.run(querry)
    # retrieved_docs = retriever.similarity_search(querry["input"])
    keywords=res.candidates[0].content.parts[0].text.strip("\n").split(",")
    print(keywords,"\n")
    data2 = fetch_data_from_wikipedia(keywords)
    # print(data,"\n")
    add_to_vector_store(data2)
    retriever=create_retriever()
    system_prompt_final=''' You are a highly advanced Language Model with Retrieval-Augmented Generation (RAG) capabilities . Follow these instructions to determine when to include the RAG part:

    When to Include the RAG Component:
    Current Events & Real-Time Information:

    If the user requests information about current events, news, or real-time updates that are likely to have changed since your last training cut-off.
    Example: "What's the latest news on the stock market?"
    Highly Specific or Niche Topics:

    If the user asks about highly specific topics or niche areas where detailed, up-to-date knowledge is critical.
    Example: "What are the latest advancements in quantum computing?"
    New Terms or Concepts:

    When the user mentions a term, concept, or entity that you have not encountered before or was likely introduced after your last update.
    Example: "Can you explain what ChatGPT-5 is?"
    Comparative or Choice Questions:

    When the user requests a comparison or needs to make a choice that might depend on the latest information or trends.
    Example: "Which is better for web development in 2024, React or Angular?"
    Product or Service Recommendations:

    When the user asks for recommendations on products, services, or tools that frequently update and have new versions.
    Example: "What's the best smartphone to buy right now?"
    When Not to Include the RAG Component:
    Static or Timeless Information:

    When the user requests information on historical events, basic scientific principles, or other topics that do not change over time.
    Example: "Explain the theory of relativity."
    General Knowledge or Common Queries:

    For common questions where the answer is unlikely to have changed and is well within the scope of your existing knowledge.
    Example: "How do I bake a chocolate cake?"
    Personal Opinions or Creative Writing:

    When the user asks for your opinion, creative content, or any input where real-time data isn't necessary.
    Example: "Write a short story about a dragon and a knight."
    Mathematical Calculations or Programming Help:

    For requests that involve performing calculations, writing code, or other tasks that rely on logical processing rather than external data.
    Example: "Can you help me solve this algebra problem?"
    Clarifications and Follow-up Questions:

    When the user asks for further explanation or clarification on a topic you have already provided information on, unless it explicitly requires updated data.
    Example: "Can you explain that concept in simpler terms?"
    General Guidelines:
    Always strive to provide the most accurate, relevant, and helpful response based on the user's query.
    If uncertain whether to use the RAG component, consider the potential benefit of the latest information to the user's request.
    Balance the use of RAG with your internal knowledge to ensure efficient and effective communication 
    The context is {context}'''
    prompt2 = ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt_final),
            ("human", "{input}"),
        ]
    )
    question_answer_chain = create_stuff_documents_chain(llm, prompt2)
    finalChain = create_retrieval_chain(retriever, question_answer_chain)
    print(finalChain.invoke(querry))
    clear_pinecone_index()



@https_fn.on_call()
def image(req: https_fn.CallableRequest):
    GOOGLE_API_KEY=os.environ.get('GOOGLE_API_KEY')
    genai.configure(api_key=GOOGLE_API_KEY)
    config = genai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='plain/text')
    model = genai.GenerativeModel('gemini-1.5-flash')
    data = req.data.get('data')
    mime_type = req.data.get('mime_type')
    filePart = {
                'mime_type': mime_type,
                'data': data
                }
    query = req.data.get('query')
    if query:
        textPart = query
    else:
        config = genai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='application/json')
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

        {
            "Danger": "No",
            "Title": "Peaceful Beach at Sunset",
            "Description": "An image capturing a peaceful beach at sunset. The sky is painted with vibrant hues of orange and pink as the sun sets over the horizon. The beach is mostly empty, with gentle waves lapping at the shore. A few seashells are scattered across the sand, and there are distant silhouettes of seagulls flying."
        }

        {
            "Danger": "Yes",
            "Title": "Busy Train Station Platform",
            "Description": "An image of a crowded train station platform. There are numerous passengers standing near the edge of the platform, waiting for the train. The platform is narrow, and there are no tactile paving strips to guide visually impaired individuals. Additionally, the fast-moving trains and the lack of clear barriers make it a potentially dangerous environment."
        }
        """
    response = model.generate_content([textPart, filePart], generation_config=config)
    print(response.candidates[0].content.parts[0].text)
    response_dict = json.loads(response.candidates[0].content.parts[0].text)
    return response_dict


@https_fn.on_call()
def video(req: https_fn.CallableRequest):
    vertexai.init(project='vision-crafters', location='us-central1')
    config = vgenai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='plain/text')
    model = vgenai.GenerativeModel('gemini-1.5-flash')
    data = req.data.get('data')
    mime_type = req.data.get('mime_type')
    filePart = vgenai.Part.from_uri(convert_to_gs_url(data), mime_type=mime_type)
    print(data)
    print(convert_to_gs_url(data))
    query = req.data.get('query')
    if query:
        textPart = query
    else:
        config = vgenai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='application/json')
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

        {
            "Danger": "No",
            "Title": "Family Picnic in a Sunny Park",
            "Description": "A video of a family enjoying a picnic in a sunny park. The area is flat and grassy, with children playing nearby and adults sitting on blankets under the shade of trees. There are picnic tables, a small playground, and a clear pathway leading to restrooms and water fountains. The environment is safe and family-friendly."
        }

        {
            "Danger": "Yes",
            "Title": "Mountain Hiking Trail with Steep Cliffs",
            "Description": "A video showing a narrow mountain hiking trail with steep cliffs on one side. The trail is rugged and uneven, with loose rocks and a steep drop-off. Hikers are seen carefully navigating the path, using trekking poles for stability. The lack of guardrails and the proximity to the cliff edge make it very dangerous for visually impaired individuals."
        }
        """
    response = model.generate_content([textPart, filePart], generation_config=config)
    print(response.candidates[0].content.parts[0].text)
    response_dict = json.loads(response.candidates[0].content.parts[0].text)
    return response_dict
