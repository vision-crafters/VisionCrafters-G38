from langchain_community.tools import WikipediaQueryRun
import time
import json
import google.generativeai as genai
from langchain_community.utilities import WikipediaAPIWrapper
from langchain_pinecone import PineconeVectorStore
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceInferenceAPIEmbeddings
import re
import os
from dotenv import load_dotenv

model_name = "mixedbread-ai/mxbai-embed-large-v1"
encode_kwargs = {'normalize_embeddings': False}

load_dotenv(".env")
import warnings
warnings.filterwarnings("ignore")
index_name="rag-application"

wrapper = WikipediaAPIWrapper(top_k_results=2, doc_content_chars_max=30000)
queryRunner = WikipediaQueryRun(api_wrapper=wrapper)
PROJECT_ID = "vision-crafters"
REGION = "asia-south1"
DATASET = "wikipedia"
TABLE = "wikipedia"
inference_api_key=os.getenv('HUGGINGFACE_INFERENCE_API_KEY')
embeddings = HuggingFaceInferenceAPIEmbeddings(
    api_key=inference_api_key, model_name="mixedbread-ai/mxbai-embed-large-v1"   
)
vectorstore=PineconeVectorStore(index_name=index_name,embedding=embeddings)

async def fetch_data_from_wikipedia(keywords):
    textsplitter = RecursiveCharacterTextSplitter(chunk_size=450, chunk_overlap=50)
    seen_titles = set()  # To keep track of unique document titles
    try:
        start_time = time.time()
        res = queryRunner.abatch_as_completed(keywords)
        
        unique_texts = []  # To store unique documents
        
        # Regular expression to match the "Page" and "Summary" structure
        page_pattern = r"Page:\s*(?P<title>.+?)\s*Summary:\s*(?P<summary>.+?)(?=Page:|$)"
        try:
            async for text in res:
                textcontent =text[1].encode('ascii', 'ignore').decode('ascii')

                matches = re.findall(pattern=page_pattern,string=textcontent,flags= re.DOTALL)

                for match in matches:
                    title, content = match
                    title = title.strip()
                    if title not in seen_titles:
                        seen_titles.add(title)
                        unique_texts.append(content.strip())
        except Exception as e:
            print(e)
        finally:
            for unique_text in unique_texts:
                chunks = textsplitter.split_text(text=unique_text)
                vectorstore.add_texts(chunks)
            
            end_time = time.time()
            print(f"Vectorization time: {end_time - start_time} seconds")

    except Exception as exc:
        print(exc)



def clear_pinecone_index():
    
    try:
        vectorstore.delete(delete_all=True)
    except Exception as e:
        print(e)
  

async def ragQuerying(data:str,query:str)->str:
    try:
        start_time=time.time()
        GOOGLE_API_KEY=os.getenv('GOOGLE_API_KEY')
        genai.configure(api_key=GOOGLE_API_KEY)
        config = genai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='application/json')

        # System prompt for the keyword fetching model
        system_prompt_keyword_fetch='''You are an advanced language model designed to extract relevant keywords from user queries.

        Keywords: Identify and list the most relevant and specific keywords from the user query. Provide the keywords in a comma-separated format.
        Image Consideration: If an image is provided along with the query, ensure that the keywords are appropriate and related to the content of both the query and the image.
        Conciseness: Ensure the keywords are concise, directly related to the main topics or concepts in the query, and specific in their combination.
        Relevance: Focus on the most important words that capture the essence of the query, aiming for more integrated and specific phrases.
        Formatting: Provide the output in JSON format.

        Additionally, create a  query that is optimized for vector searching. This query should be structured to yield effective search results and may vary slightly from the primary query to enhance search performance.

        Examples:

        Query: "Show me the latest trends in AI technology."
        Output:
        {
        "keywords": "latest trends in AI, AI technology trends, artificial intelligence advancements",
        "vector_search_query": "Latest trends in artificial intelligence technology"
        }

        Query with Image: A picture of a Tesla car with the query "Tell me about this."
        Output:
        {
        "keywords": "Tesla electric car, Tesla vehicle features, automotive technology, Tesla Model",
        "vector_search_query": "Features and technology of Tesla electric cars"
        }

        Query: "Best practices for remote work productivity."
        Output:
        {
        "keywords": "best practices for remote work, remote work productivity tips, work from home efficiency",
        "vector_search_query": "Tips for improving remote work productivity"
        }

        Query with Image: An image of a beach with the query "What activities can I do here?"
        Output:
        {
        "keywords": "beach activities, seaside recreational activities, water sports, beach games",
        "vector_search_query": "Popular activities at the beach"
        }

        Use this format to process queries and images provided.'''
        
        #Initializing the gemini model for generating the keywords and the vector search query 
        model = genai.GenerativeModel('gemini-1.5-flash',system_instruction=system_prompt_keyword_fetch)
            
        textpart =query
        base64_image = data
        image = {
            'mime_type': 'image/jpeg',
            'data': base64_image
        }
        if(not base64_image):
            raise Exception("Image not found")
        if(not textpart):
            raise Exception("Query not found")
        
        # Generating the keywords and the vector search query
        res=model.generate_content([textpart, image], generation_config=config)
        response=json.loads(res.candidates[0].content.parts[0].text)
        print(response)
        keywords=response["keywords"].split(",")

        # Fetching the data from wikipedia using the keywords and vectorizing the data into the pinecone vectorstore
        await fetch_data_from_wikipedia(keywords)
        

        context=None
        retries=0
        while(not context): # This loop will try to get the context from the vectorstore with upto 5 retries
            retries+=1
            if retries>5:
                print("No context found, maximum retries reached")
                break
            context=vectorstore.similarity_search(response["vector_search_query"],k=3)
        if context:
            for doc in context:
                print(str(doc["text"]))
        prompt=f"System prompt: Please answer the following question. If the question requires additional context to answer, use the provided documents in the context.\n context: {context}\n question: {textpart}\n"

        return prompt
    except Exception as e:
        print(e)
    finally:
        clear_pinecone_index()
        1
