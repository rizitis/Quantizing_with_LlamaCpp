Script is based on [GratisStudio](https://github.com/3Simplex/GratisStudio/blob/main/LlamaCpp/Quantizing_with_LlamaCpp.md) HowTo for windows.   
It is tested on Slackware64 current systems without issues. If you found a bug please open an issue. 

## Reqirements to run script:
1.
```
python3.11--> {numpy,sentencepiece,gguf}

```
2.
```
GPT4All(LLM environment):
Slackers --> https://github.com/rizitis/GPT4All.SlackBuild
Rest distro--> search for gpt4all at your distro package manager or use ubuntu installer  https://gpt4all.io/index.html 
```
3.
```
git lfs 
```
4.
```
   ========= OPTIONAL:============= 
     Vulkan SDK (AMD GPU Support)  
     Cuda toolkit (Nvidia GPU Support) 
     ********************************   
```

Normally all other needs should be by default in your distro, if not..when script fail read what is missing and install from your distro package manager. 


## USAGE
1. When you find the LL model you want from [https://huggingface.co](https://huggingface.co)<br>
Copy model url, then; <br>
2. Open script with your favore text editor (emacs,vim,nano,gedit etc..)<br>
Find this line and replace url with yours.
 ```
 #---------------------------------------------------------------------------------------------------------------------#
MODEL_URL=https://huggingface.co/NousResearch/Hermes-2-Pro-Llama-3-8B			#<---Replace or add your model repo URL
#---------------------------------------------------------------------------------------------------------------------#

```

3. Next move is to make script executable if not...<br>
`chmod +x quantizing_ai_models.sh`<br>

4. Finaly run script `./quantizing_ai_models.sh`

5. Just answer questions if needed and wait for results... 

### NOTE:
**Warning: Running this script as root is not recommended.**

## Supported models
mistral
llama
llama3