## Homework for lab.

### Use terrafrom to create infrastructure on GCP.

1. Using google cloud-sdk docker image. Build working container based on image, install TF. 
2. Starting container (cloud-sdk+tf) and attach working directory to container.

```
docker run -it --rm -v ${PWD}:/work -w /work <IMAGE_NAME>
```

3. Autheticate with GCP project, choose project for working. 

```
gcloud auth login

gcloud config set project PROJECT_ID
```

4. Creating service account for tf, create .json key and use it in .tf files.

5. Creating infrastructure.