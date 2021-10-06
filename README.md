# About
This is instruction on how to create a Docker image that you can use to build a single executable file of your python project. It uses Pyinstaller inside the docker container. The instuctions are ment to be used on a Linux computer. You can build three different docker images that can be used to create python executables for Linux, Windows32 and Windows64.

# Proxy
There are several included programs that needs internet access. If you are behind a proxy you need to do the following to make this project work...
- **Docker images**  
  For docker to be able to fetch images from an Internet repository, you need to enter the following info in /etc/systemd/system/docker.service.d/proxy.conf
  ```
  Environment="HTTP_PROXY=http://<your proxy:port>"
  Environment="HTTPS_PROXY=http://<your proxy:port>"
  Environment="NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
  ```
- **Docker run commands like wget and pip**  
  For docker to be able to run commands like wget and pip inside the run command you need to the set following info in ~/.docker/config.json
  ```
  {
    "proxies":
    {
      "default":
      {
        "httpProxy": "<your proxy:port>",
        "httpsProxy": "<your proxy:port>",
        "noProxy": "localhost,127.0.0.0/8,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
      }
    }
  }
  ```
- **Proxy authorization**  
  You also need to authenticate to the proxy. An easy way to do this is to open your browser and browse to any page on the Internet. Your browser will then take care of the authentication and this will work for some time.

# Build image on your own
1. Clone this git
   ```$ git clone git@github.com:smicker/docker_build_python_executable.git```
2. ```$ cd <the cloned git folder>```
3. Decide if you want to create a docker image to be used for Linux, Windows32 or Windows64. Then rename the corresponding Dockerfile-* to just Dockerfile.
4. Open Dockerfile and set the OS version that you want. Default is **debian:buster** (Note, if you change this for the Windows versions you also need to change the winehq repository so it matches the OS, like debian)
5. Also in the Dockerfile, set the version of python and pyinstaller that you want. Default is **python=3.7.5** and **pyinstaller=4.5.1**
6. Build your image with:
   ```$ docker build -t <your_image_name> .```  
   for example:  
   ```$ docker build -t pyinstaller-linux-image .```  
   You will get an image with the name **pyinstaller-linux-image**  
   (note, this will take some minutes) 
7. You can verify that you now have a docker image with this name by
   ```$ docker images```

# Load prebuilt image
After you image has been built you can actually store the image as a tar by: ```docker save -o pyinstaller-linux-image.tar pyinstaller-linux-image```. And if you already have such a tar file you can just load it into the docker cache so you don't need to built it yourself.  
Example of loading the tar file image that was saved above:  
```docker load -i pyinstaller-linux-image```  
I would have loved to include the three possible images that can be built with this git, into this git. However, each file becomes between 2-3 Gb which is to big to check into git.

# Using your image - Building your python executable
1. Browse to your python project folder
   ```$ cd <my python project folder>```  
   Note that this does not have to be the same folder as you cloned this git to.
2. Make sure that you have your main python file in the current folder. Also, if you need python packages to be installed, make sure that you have a requirements.txt file in this same folder, that contains all required packages. Those packages will be installed by the entrypoint script inside your docker container when you start your docker image.
3. Now, depending on if you want to build with the default pyinstaller settings, proceed to step 4. Or if you need custom pyinstaller settings, proceed to step 5 (most common).
4. Building with default pyinstaller settings means that, when you run your image, the entrypoint.sh script will run the pyinstaller like:  
   *pyinstaller --clean -y --dist ./dist/linux --workpath /tmp \*.spec*  
   or corresponding  
   pyinstaller --clean -y --dist ./dist/windows --workpath /tmp \*.spec*  
   It will require that you also have a .spec file in your python project folder. To create a .spec file you need to install and run pyinstaller once locally (outside of docker).  
   To start the build, just run your docker image like below  
   ```$ docker run --rm -v "$(pwd):/src/" pyinstaller-linux-image```  
   or  
   ```$ docker run --rm -v "$(pwd):/src/" pyinstaller-windows32-image```  
   or  
   ```$ docker run --rm -v "$(pwd):/src/" pyinstaller-windows64-image```
5. Building with custom pyinstaller settings. This does not require that you have a .spec file. Start your docker image like below:  
   ```$ docker run --rm -v "$(pwd):/src/" pyinstaller-linux-image “pyinstaller <your custom pyinstaller settings> <name of your python main file>”```  
   (Change *pyinstaller-linux-image* to *pyinstaller-windows32-image* or *pyinstaller-windows64-image* if you want to build a windows .exe file instead)  
     
   Example:  
   ```$ docker run --rm -v "$(pwd):/src/" pyinstaller-linux-image "pyinstaller --onefile --workpath /tmp -y --dist ./dist/linux -w --add-data templates:templates --add-data static:static my_main_script.py"```
6. Your built python executable can then be found under **\<your python project folder>/dist/[linux | windows]/**  
   Limitations: Unfortunately the executable will have root as owner but it is easy to change with:  
   ```$ sudo chown -R $USER ./dist```  
   The generated file *.spec can safely be deleted.

# Add extras to be run inside container during image startup
If you need extra commands to be run prior to running the entrypoint.sh script when you start your image, you can add it like this:  
```$ docker run --rm -v "$(pwd):/src/" --entrypoint /bin/bash pyinstaller-linux-image -c "apt-get update -y && apt-get install python3 -y && python3 -m pip install --upgrade pip && /entrypoint.sh <’optional entrypoint args’>"```  
The **--entrypoint** tag will override the default entrypoint command that was set when the image was built. So now instead it will start bash and then run the commands after the -c argument. Since we enter “&& /entrypoint.sh” at the end the entrypoint.sh script will be executed after your added commands.

# Problems
If you get problems when running the docker image you can make it ignore the entrypoint script so that it instead starts as a container with your terminal ending up inside it. You can then run commands inside the container to test things out. If you want to test the entrypoint script inside the container you can find it under /entrypoint.sh.  
To start without running the entrypoint script, do like this:  
```$ docker run --rm -it -v "$(pwd):/src/" --entrypoint /bin/bash pyinstaller-linux-image```

