from langchain_community.tools import WikipediaQueryRun
from langchain_community.utilities import WikipediaAPIWrapper
from langchain.chains import  create_retrieval_chain,LLMChain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_pinecone import PineconeVectorStore
from langchain_cohere import CohereEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
import concurrent.futures
import os
from dotenv import load_dotenv
print(load_dotenv())
from pinecone import Pinecone
import warnings
warnings.filterwarnings("ignore")
index_name="rag-application"
embedding_model = embeddings=CohereEmbeddings(model="embed-english-v3.0")
wrapper = WikipediaAPIWrapper(top_k_results=5, doc_content_chars_max=10000)
queryRunner = WikipediaQueryRun(api_wrapper=wrapper)
def fetch_keyword_data(keyword):
    return queryRunner.run(tool_input=keyword)

def fetch_data_from_wikipedia(keywords):
    data = []
    textsplitter=RecursiveCharacterTextSplitter(chunk_size=1000,chunk_overlap=2,add_start_index=True)
    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_to_keyword = {executor.submit(fetch_keyword_data, keyword): keyword for keyword in keywords}
        for future in concurrent.futures.as_completed(future_to_keyword):
            try:
                text = future.result()
                chunks=textsplitter.split_text(text=text)
                data.extend(chunks)
            except Exception as exc:
                print(f"Keyword {future_to_keyword[future]} generated an exception: {exc}")
    return data
def clear_pinecone_index():
    vectorstore=PineconeVectorStore(index_name=index_name,embedding=embeddings)
    try:
        vectorstore.delete(delete_all=True)
    except Exception as e:
        print(e)

def add_to_vector_store(data):
    # Initialize OpenAI Embeddings
    
    vectorstore = PineconeVectorStore(embedding=embeddings,index_name=index_name)

    # Initialize vector store
    vectorstore.add_texts(data)
    
def create_retriever():
    # Initialize vector store
    vectorstore = PineconeVectorStore(embedding=embeddings,index_name=index_name)

    # Return retriever
    return vectorstore.as_retriever(search_type="similarity", search_kwargs={"k": 1},output_variable={"context"})


