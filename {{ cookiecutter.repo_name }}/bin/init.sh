#!/bin/bash

source /opt/conda/etc/profile.d/conda.sh
PROJECT_NAME=ds-project
VENV_DIR=$HOME/work/venv/$PROJECT_NAME
if [ ! -d $VENV_DIR ] 
then
        echo "Creating venv for ML project"
        conda create python=$PYTHON_MINOR -p $VENV_DIR -y 
        conda activate $VENV_DIR
        pip install kedro==$KEDRO_VERSION
else
        echo "Venv for ML project already exists: $VENV_DIR "
        conda activate $VENV_DIR
fi


CONFIG_FILE=config.yaml
cat <<EOF >> $CONFIG_FILE
output_dir: $HOME/work/git
project_name: Datascience project
repo_name: $PROJECT_NAME
python_package: ${PROJECT_NAME//-/_}
EOF

PROJECT_DIR=$HOME/work/git/$PROJECT_NAME
if [ ! -d $PROJECT_DIR ] 
then
        TAG=${1:-"master"}
        echo "Using starter using tag: $TAG"
        kedro new --verbose --starter https://github.com/biodatageeks/kedro-pyspark --checkout $TAG --config $CONFIG_FILE
        rm $CONFIG_FILE
        cd $PROJECT_DIR
        kedro install
        kedro mlflow init
        sed -i 's/mlflow_tracking_uri: mlruns/mlflow_tracking_uri: http:\/\/localhost:5000/g' conf/local/mlflow.yml
        cp conf/local/mlflow.yml conf/local-spark/
        conda deactivate
else
        echo "Directory with project exists: $PROJECT_DIR"
fi

KERNEL_NAME=ds-kedro
KERNEL_FILE=$HOME/.local/share/jupyter/kernels/$KERNEL_NAME/kernel.json
if [ ! -f $KERNEL_FILE ] 
then
        echo "Creating Jupyter kernel"
        ipython kernel install --name $KERNEL_NAME --display-name "Kedro (datascience)" --user
        echo -e "
        {
        \"argv\": [
        \"$VENV_DIR/bin/python3\",
        \"-m\",
        \"ipykernel_launcher\",
        \"-f\",
        \"{connection_file}\",
        \"--ipython-dir\",
        \"$HOME/work/git/$PROJECT_NAME/.ipython\"
        ],
        \"env\":{
        \"KEDRO_ENV\": \"local-spark\",
        \"PYTHONPATH\": \"$PYTHONPATH:$HOME/work/git/$PROJECT_NAME/src\" 
        },
        \"display_name\": \"Kedro (datascience)\",
        \"language\": \"python\"
        }" > $KERNEL_FILE
else
        echo "Jupyter kernel already exists: $KERNEL_FILE"
fi

conda activate $VENV_DIR