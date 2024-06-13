from langchain_community.tools import WikipediaQueryRun
import asyncio
import time
import json
import google.generativeai as genai
from langchain_community.utilities import WikipediaAPIWrapper
from langchain.chains import  create_retrieval_chain,LLMChain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_pinecone import PineconeVectorStore
from langchain_cohere import CohereEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os
from dotenv import load_dotenv
load_dotenv()
import warnings
warnings.filterwarnings("ignore")
index_name="rag-application"
embedding_model = embeddings=CohereEmbeddings(model="embed-english-v3.0")
wrapper = WikipediaAPIWrapper(top_k_results=10, doc_content_chars_max=20000)
queryRunner = WikipediaQueryRun(api_wrapper=wrapper)
vectorstore=PineconeVectorStore(index_name=index_name,embedding=embeddings)
def fetch_keyword_data(keyword):
    return queryRunner.run(tool_input=keyword)

async def  fetch_data_from_wikipedia(keywords):
    textsplitter=RecursiveCharacterTextSplitter(chunk_size=3000,chunk_overlap=2)
    try:
        start_time = time.time()
        res=queryRunner.abatch_as_completed(keywords)
        async for text in res:
            chunks=textsplitter.split_text(text=text[1])
            print(len(text[1]))
            vectorstore.add_texts(chunks)
        end_time = time.time()
        print(f"Elapsed time: {end_time - start_time} seconds")        
    except Exception as exc:
        print(exc)
def clear_pinecone_index():
    
    try:
        vectorstore.delete(delete_all=True)
    except Exception as e:
        print(e)

async def rag_querring(req):
    try:
        GOOGLE_API_KEY=os.environ.get('GOOGLE_API_KEY')
        genai.configure(api_key=GOOGLE_API_KEY)
        config = genai.GenerationConfig(max_output_tokens=1024, temperature=0.6, response_mime_type='application/json')

        system_prompt_keyword_fetch='''You are an advanced language model designed to extract relevant keywords from user queries and transform the query into a combined question that integrates the image content (if provided) and the query. Follow these guidelines:
        Keywords: Identify and list the most relevant and specific keywords from the user query. Provide the keywords in a comma-separated format.
        Image Consideration: If an image is provided along with the query, ensure that the keywords are appropriate and related to the content of both the query and the image.
        Conciseness: Ensure the keywords are concise, directly related to the main topics or concepts in the query, and specific in their combination.
        Relevance: Focus on the most important words that capture the essence of the query, aiming for more integrated and specific phrases.
        Formatting: Provide the output in JSON format.
        Examples:

        Query: "Show me the latest trends in AI technology."
        Output:{
        "keywords": "latest trends in AI, AI technology trends, artificial intelligence advancements",
        "query": "What are the latest trends in AI technology?"
        }


        Query with Image: A picture of a Tesla car with the query "Tell me about this."
        Output:{
        "keywords": "Tesla electric car, Tesla vehicle features, automotive technology, Tesla Model",
        "query": "Tell me about this Tesla electric car and its features."
        }


        Query: "Best practices for remote work productivity."
        Output:{
        "keywords": "best practices for remote work, remote work productivity tips, work from home efficiency",
        "query": "What are the best practices for remote work productivity?"
        }

        Query with Image: An image of a beach with the query "What activities can I do here?"
        Output:{
        "keywords": "beach activities, seaside recreational activities, water sports, beach games",
        "query": "What activities can I do at the beach?"
        }

        Use this format to process queries and images provided.'''
        model = genai.GenerativeModel('gemini-1.5-flash',system_instruction=system_prompt_keyword_fetch)
        llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash",temperature=0.6)
        textpart =  req.data.get('query')
        
        img_data = req.data.get('data')
        mime_type = req.data.get('mime_type')
        filePart = {
                'mime_type': mime_type,
                'data': img_data
                }
        res=model.generate_content([textpart, filePart], generation_config=config)
        response=json.loads(res.candidates[0].content.parts[0].text)
        print(response)

        keywords=response["keywords"].split(",")
        querry={"input":response["query"]}
        await fetch_data_from_wikipedia(keywords)
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

        When asked the question including the image just ignore because the context provided by the image is already included in then context given below.
        '''
        prompt2 = ChatPromptTemplate.from_messages(
            [
                ("system", system_prompt_final+'The context is {context}'),
                ("human", "{input}"),
            ]
        )
        context=vectorstore.similarity_search(querry["input"],k=1)
        # system_prompt_final=system_prompt_final+str(context)
        querry["context"]=context
        question_answer_chain = create_stuff_documents_chain(llm, prompt2)
        finalChain = LLMChain(llm=llm, prompt=prompt2)
        finalresponse=finalChain.invoke(querry)
    #     model2=genai.GenerativeModel('gemini-1.5-flash',system_instruction=system_prompt_final)
    #     finalresponse=model2.generate_content([str(querry), image], generation_config=config)
        # print(querry)
        print(finalresponse)
    except Exception as e:
        print(e)
    finally:
        clear_pinecone_index()

