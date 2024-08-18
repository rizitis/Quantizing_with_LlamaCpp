#!/bin/bash


# 05/2024 rizitis Copyrights none.
# Script for Quantizing_with_LlamaCpp AI models for Slackware64-current systems.
# Based on https://github.com/3Simplex/GratisStudio/blob/main/LlamaCpp/Quantizing_with_LlamaCpp.md HOWTO.

# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# ****************************************************************************#
# ========== Needed:==============                                            #
## 1. python3.11 --> {numpy,sentencepiece,gguf}                               #
## 2. GPT4All(LLM environment)-> https://github.com/rizitis/GPT4All.SlackBuild#
## https://gpt4all.io/index.html OR from your package manager                 #
## 3. git lfs                                                                 #
# ============================================================================#
#                                                                             #
# ========= OPTIONAL:=============                                            #
## Vulkan SDK (AMD GPU Support)                                               #
## Cuda toolkit (Nvidia GPU Support)                                          #
# ****************************************************************************#

#---------------------------------------------------------------------------------------------------------------------#
MODEL_URL="$1"			#<---Replace or add your model repo URL. Else execute script like this: ./quantizing_ai_models.sh <https://huggingface.co/.... >
#---------------------------------------------------------------------------------------------------------------------#

if [ "$(id -u)" -eq 0 ]; then
  echo -e "${RED}Warning: Running this script as root is not recommended.${RESET}"
  echo -e "${RED}Please run as a regular user with appropriate permissions.${RESET}"
  exit 8
fi

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RESET='\033[0m'
# Run script to your $USER (not root) path assusme ~/ or ~/BUILDS_DIR
PWD=$(pwd)
echo -e "${BLUE}Party start in $PWD ${RESET}"
CWD="$PWD"/llama.cpp




# This URL never change.
LLAMA_URL=https://github.com/ggerganov/llama.cpp.git



cat << "EOF"
   ,--,      ,--,                                                  
,---.'|   ,---.'|                            ____                  
|   | :   |   | :      ,---,               ,'  , `.   ,---,        
:   : |   :   : |     '  .' \           ,-+-,.' _ |  '  .' \       
|   ' :   |   ' :    /  ;    '.      ,-+-. ;   , || /  ;    '.     
;   ; '   ;   ; '   :  :       \    ,--.'|'   |  ;|:  :       \    
'   | |__ '   | |__ :  |   /\   \  |   |  ,', |  '::  |   /\   \   
|   | :.'||   | :.'||  :  ' ;.   : |   | /  | |  |||  :  ' ;.   :  
'   :    ;'   :    ;|  |  ;/  \   \'   | :  | :  |,|  |  ;/  \   \ 
|   |  ./ |   |  ./ '  :  | \  \ ,';   . |  ; |--' '  :  | \  \ ,' 
;   : ;   ;   : ;   |  |  '  '--'  |   : |  | ,    |  |  '  '--'   
|   ,/    |   ,/    |  :  :        |   : '  |/     |  :  :         
'---'     '---'     |  | ,'        ;   | |`-'      |  | ,'         
                    `--''          |   ;/          `--''           
                                   '---'                           
                                                                   
EOF

sleep 3

JOBS=-j$(getconf _NPROCESSORS_ONLN)

set -e

if [ -d "llama.cpp" ]; then
    echo -e "${GREEN} Folder llama.cpp exists${RESET}"
    cd llama.cpp || exit 1
    git pull origin
 else
    echo -e "${GREEN}Folder llama.cpp does not exist.${RESET}"
 git clone --recurse-submodules "$LLAMA_URL"
 cd llama.cpp || exit 1
 git pull origin
 mkdir -p build
 cd build || exit 1

# Question to build with GPU (Vulkan) support
 echo -e "${BLUE}Do you want to build with GPU (Vulkan) support? (yes/no):${RESET}"
 read BUILD_WITH_GPU

 if [[ "$BUILD_WITH_GPU" == "yes" ]]; then
  echo -e "${GREEN}Building with GPU support...${RESET}"  
  # CMake commands for building with GPU support
  cmake .. -DLLAMA_VULKAN=ON -DLLAMA_NATIVE=ON
  cmake --build . --config Release "$JOBS"
  
 elif [[ "$BUILD_WITH_GPU" == "no" ]]; then
  echo -e "${GREEN}Building without GPU support...${RESET}"  
  # CMake commands for building without GPU support (CPU only)
  cmake .. -DLLAMA_NATIVE=ON
  cmake --build . --config Release "$JOBS"
  
 else
  echo -e "${RED}Invalid input. Please enter 'yes' or 'no'.${RESET}"
  exit 
 fi
fi 

cd "$CWD"/models || exit 1

git lfs install
set +e
git clone "$MODEL_URL"
set -e # we dont need what is disabled for security reasons but we also dont like script to stop :)
# Lets use some of the hidden power bash scripting has ;)
# Get all models directories
MATCHING_DIRS=$(find . -maxdepth 1 -type d)

# Remove current directory reference ('.') if necessary
MATCHING_DIRS=$(echo "$MATCHING_DIRS" | sed 's|^\./||')

# Check if any matches are found
if [ -n "$MATCHING_DIRS" ]; then
  MATCHING_ARRAY=($MATCHING_DIRS)
  
  # If there is more than one directory, user must choose
  if [ ${#MATCHING_ARRAY[@]} -gt 1 ]; then
    echo -e "${GREEN}Multiple models directories found:${RESET}"
    for i in "${!MATCHING_ARRAY[@]}"; do
      echo "[$i] ${MATCHING_ARRAY[$i]}"
    done

    # Choose a directory index
    read -p "Choose a directory by number (0-$((${#MATCHING_ARRAY[@]} - 1))): " USER_CHOICE
    
    # Validate choice
    if [[ $USER_CHOICE =~ ^[0-9]+$ ]] && [ "$USER_CHOICE" -ge 0 ] && [ "$USER_CHOICE" -lt ${#MATCHING_ARRAY[@]} ]; then
      TARGET_DIR=${MATCHING_ARRAY[$USER_CHOICE]}
      cd "$TARGET_DIR" || exit 1      
    else
      echo -e "${RED}Invalid choice. Exiting.${RESET}"
      exit
    fi
  else
    # If only one directory is found, get in ;)
    TARGET_DIR="${MATCHING_ARRAY[0]}"
    cd "$TARGET_DIR" || exit 1
  fi
else
  echo -e "${RED}Hm...no model directories found.${RESET}"
  echo -e "${RED}Who wrote this script?${RESET}"
  exit 69
fi
 
 echo -e "${BLUE}Are you converting a llama model, ggml or mistral? $TARGET_DIR (llama/mistral/ggml):${RESET}"
  read BPE_LLAMA_MISTRAL
  
  if [ "$BPE_LLAMA_MISTRAL" == "ggml" ]; then
  python3 convert_llama_ggml_to_gguf.py models/"$TARGET_DIR"/ --outtype f16
 mv "$CWD"/models/"$TARGET_DIR"/ggml-model-f16.gguf  "$CWD"/build/bin/ 

if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to move ggml-model-f16.gguf to $CWD/bin/ ${RESET}"
  exit 2
else
  echo -e "${GREEN}File moved successfully $CWD/bin/ keep going...${RESET}"
fi

cd "$CWD/build/bin/"  || exit 1
chmod +x llama-quantize || exit 3
./llama-quantize ggml-model-f16.gguf ggml-model-Q4_0.gguf Q4_0

GGUF_FILES=$(ls "ggml-model-Q4_0.gguf" 2>/dev/null)

# Count 
FILE_COUNT=$(echo "$GGUF_FILES" | wc -l)

if [ "$FILE_COUNT" -eq 0 ]; then
  echo -e "${RED}Error: File 'ggml-model-Q4_0.gguf' not found.${RESET}"
  exit 3
elif [ "$FILE_COUNT" -gt 1 ]; then
  echo -e "${RED}Error: Multiple files found with the name 'ggml-model-Q4_0.gguf'. Cannot proceed.${RESET}"
  echo "$GGUF_FILES"
  exit 3
else
  mv "ggml-model-Q4_0.gguf" "${TARGET_DIR}-Q4_0.gguf"
fi
  # Check if the rename (mv) command was successful
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}File renamed to ${TARGET_DIR}-Q4_0.gguf ${RESET}"
  else
    echo -e "${RED}Error: Failed to rename file.${RESET}"
    exit 3
  fi
else
  echo ""
fi     
  
 if [ "$BPE_LLAMA_MISTRAL" == "llama" ]; then
  
# Some day I will be a h4ker, for now thats all...
echo -e "${BLUE}Are you converting a Llama3 model? $TARGET_DIR (yes/no):${RESET}"
 read BPE_FILE_FOUND


# After last changes in lamma.cpp I will keep this here for a wile just for people that dont update their lamma.cpp (91,92)
# If you dont have a very importand reason then suggested to follow llamm.cpp updates...
# I will keep convert.py here but not for ever special if script some day break I will absolutly remove it. 
if [ "$BPE_FILE_FOUND" == "yes" ]; then
    echo -e "${GREEN}Yupiii, Llama3 model found: $BPE_FILE_FOUND ${RESET}"
    cd "$CWD" || exit 1
    if python3 convert_hf_to_gguf.py  models/"$TARGET_DIR"/ --outtype f16 --vocab-type bpe; then
        echo -e "${GREEN}Conversion successful using --vocab-type bpe${RESET}"
    else
        echo -e "${RED}Conversion using --vocab-type bpe failed, trying alternative...${RESET}"
        if python3 convert_hf_to_gguf.py --outtype f16 models/"$TARGET_DIR"/; then
            echo -e "${GREEN}Conversion successful using convert-hf-to-gguf.py --outtype f16${RESET}"
        else
            echo -e "${RED}Both conversion methods failed${RESET}"
            exit 66
        fi
    fi
else
    echo -e "${GREEN}No llama3 $TARGET_DIR ${RESET}"
    cd "$CWD" || exit 1
    if python3 examples/convert_legacy_llama.py models/"$TARGET_DIR"/ --outtype f16 --vocab-type bpe; then
        echo -e "${GREEN}Conversion successful using convert.py${RESET}"
    else
        echo -e "${RED}Conversion using --vocab-type bpe failed, trying alternative...${RESET}"
        if python3 examples/convert_legacy_llama.py models/"$TARGET_DIR"/ --outtype f16; then
            echo -e "${GREEN}Conversion successful using convert-hf-to-gguf.py${RESET}"
        else
            echo -e "${RED}Both conversion methods failed${RESET}"
            exit 66
        fi
    fi
fi


mv "$CWD"/models/"$TARGET_DIR"/ggml-model-f16.gguf  "$CWD"/build/bin/ 

if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Failed to move ggml-model-f16.gguf to $CWD/bin/ ${RESET}"
  exit 2
else
  echo -e "${GREEN}File moved successfully $CWD/bin/ keep going...${RESET}"
fi

cd "$CWD/build/bin/"  || exit 1
chmod +x llama-quantize || exit 3
./llama-quantize ggml-model-f16.gguf ggml-model-Q4_0.gguf Q4_0

GGUF_FILES=$(ls "ggml-model-Q4_0.gguf" 2>/dev/null)

# Count 
FILE_COUNT=$(echo "$GGUF_FILES" | wc -l)

if [ "$FILE_COUNT" -eq 0 ]; then
  echo -e "${RED}Error: File 'ggml-model-Q4_0.gguf' not found.${RESET}"
  exit 3
elif [ "$FILE_COUNT" -gt 1 ]; then
  echo -e "${RED}Error: Multiple files found with the name 'ggml-model-Q4_0.gguf'. Cannot proceed.${RESET}"
  echo "$GGUF_FILES"
  exit 3
else
  mv "ggml-model-Q4_0.gguf" "${TARGET_DIR}-Q4_0.gguf"

  # Check if the rename (mv) command was successful
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}File renamed to ${TARGET_DIR}-Q4_0.gguf ${RESET}"
  else
    echo -e "${RED}Error: Failed to rename file.${RESET}"
    exit 3
  fi
fi

else
[ "$BPE_LLAMA_MISTRAL" == "mistral" ]
echo "MISTRAL..."
sleep 2
cd "$CWD" || exit 1
# Convert to fp16
# convert.py is removed ... so we use examples/convert-legacy-llama.py
# If you havent update you llama.cpp and script fail uncomment next line and comment the next one:

#python3 convert.py models/"$TARGET_DIR"/ --pad-vocab --outtype f16 
python3 examples/convert_legacy_llama.py models/"$TARGET_DIR"/ --pad-vocab --outtype f16


mv "$CWD"/models/"$TARGET_DIR"/*.gguf  "$CWD"/build/bin/ggml-model-f16.gguf || exit 12

# llama-quantize the model for each method in the QUANTIZATION_METHODS list
cd "$CWD/build/bin/"  || exit 1

method="q4_k_m"
chmod +x llama-quantize || exit 3
./llama-quantize ggml-model-f16.gguf ggml-model-Q4_0.gguf $method


GGUF_FILES=$(ls "ggml-model-Q4_0.gguf" 2>/dev/null)
echo "$GGUF_FILES"

# Count 
FILE_COUNT=$(echo "$GGUF_FILES" | wc -l)


if [ "$FILE_COUNT" -eq 0 ]; then
  echo -e "${RED}Error: File '.gguf' not found.${RESET}"
  exit 3
elif [ "$FILE_COUNT" -gt 1 ]; then
  echo -e "${RED}Error: Multiple files found with the name 'ggml-model-Q4_0.gguf'. Cannot proceed.${RESET}"
  echo "$GGUF_FILES"
  exit 3
else
  mv "$GGUF_FILES" "${TARGET_DIR}-Q4_0.gguf"

  # Check if the rename (mv) command was successful
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}File renamed to ${TARGET_DIR}-Q4_0.gguf ${RESET}"
    echo -e "${GREEN}Model moved to llama.cpp/build/bin/${RESET}"
  else
    echo -e "${RED}Error: Failed to rename or model is not moved to llama.cpp/build/bin/${RESET}"
    exit 3
  fi
fi


fi
echo -e "${GREEN}SUCCESS...${RESET}"
echo ""
echo ""
echo "You can now load llama.cpp/build/bin/${TARGET_DIR}-Q4_0.gguf using:"
cat << "EOF"
.----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |    ______    | || |   ______     | || |  _________   | || |   _    _     | || |      __      | || |   _____      | || |   _____      | |
| |  .' ___  |   | || |  |_   __ \   | || | |  _   _  |  | || |  | |  | |    | || |     /  \     | || |  |_   _|     | || |  |_   _|     | |
| | / .'   \_|   | || |    | |__) |  | || | |_/ | | \_|  | || |  | |__| |_   | || |    / /\ \    | || |    | |       | || |    | |       | |
| | | |    ____  | || |    |  ___/   | || |     | |      | || |  |____   _|  | || |   / ____ \   | || |    | |   _   | || |    | |   _   | |
| | \ `.___]  _| | || |   _| |_      | || |    _| |_     | || |      _| |_   | || | _/ /    \ \_ | || |   _| |__/ |  | || |   _| |__/ |  | |
| |  `._____.'   | || |  |_____|     | || |   |_____|    | || |     |_____|  | || ||____|  |____|| || |  |________|  | || |  |________|  | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'
EOF

