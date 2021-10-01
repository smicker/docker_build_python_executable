# About
This is instruction on how to create a Docker image that you can use to build a single executable file of your python project. It uses Pyinstaller inside the docker container.

# Create image
1. Clone this git
   ```$ git clone ...```
2. ```$ cd <the cloned git folder>```
3. Open Dockerfile and set the OS version that you want
   Default is **debian:buster**
4. Also in the Dockerfile, set the version of python and pyinstaller that you want. Default is **python=3.7.5** and **pyinstaller=4.5.1**
5. Build your image with:
   ```$ docker build -t my-pyinstaller-linux .```  
   You will get an image with the name **my-pyinstaller-linux**  
   (note, this will take some minutes) 
6. You can verify that you now have a docker image with this name by
   ```$ docker images```

# Using your image - Building your python executable
1. Browse to your python project folder
   ```$ cd <my python project folder>```  
   Note that this does not have to be the same folder as you cloned this git to.
2. Make sure that you have your main python file in the current folder. Also, if you need python packages to be installed, make sure that you have a requirements.txt file in this same folder, that contains all required packages. Those packages will be installed by the entrypoint script inside your docker container when you start your docker image.
3. Now, depending on if you want to build with the default pyinstaller settings, proceed to step 4. Or if you need custom pyinstaller settings, proceed to step 5 (most common).
4. Building with default pyinstaller settings means that it will be built with the below command:  
   *pyinstaller --clean -y --dist ./dist/linux --workpath /tmp \*.spec*  
   It will require that you also have a .spec file in your python project folder. To create a .spec file you need to run pyinstaller once locally (outside of docker).  
   To start the build, just run your docker image like below  
   ```$ docker run --rm -v "$(pwd):/src/" my-pyinstaller-linux```
5. Building with custom pyinstaller settings. This does not require that you have a .spec file. Start your docker image like below:  
   ```$ docker run --rm -v "$(pwd):/src/" my-pyinstaller-linux “pyinstaller <your custom pyinstaller settings> <name of your python main file>”```  
     
   Example:  
   ```$ docker run --rm -v "$(pwd):/src/" my-pyinstaller-linux "pyinstaller --onefile --workpath /tmp --dist ./dist/linux -w -F --add-data templates:templates --add-data static:static flaskblog.py"```
6. Your built python executable can then be found under **\<your python project folder>/dist/linux/**  
   Limitations: Unfortunately the executable will have root as owner but it is easy to change with:  
   ```$ sudo chown -R $USER ./dist```  
   The generated file *.spec can safely be deleted.

# Add extras to be run inside container during image startup
If you need extra commands to be run prior to running the entrypoint.sh script when you start your image, you can add it like this:  
```$ docker run --rm -v "$(pwd):/src/" --entrypoint /bin/bash my-pyinstaller-linux -c "apt-get update -y && apt-get install python3 -y && python3 -m pip install --upgrade pip && /entrypoint.sh <’optional entrypoint args’>"```  
The **--entrypoint** tag will override the default entrypoint command that was set when the image was built. So now instead it will start bash and then run the commands after the -c argument. Since we enter “&& /entrypoint.sh” at the end the entrypoint.sh script will be executed after your added commands.

# Problems
If you get problems when running the docker image you can make it ignore the entrypoint script so that it instead starts as a container with your terminal ending up inside it. You can then run commands inside the container to test things out. If you want to test the entrypoint script inside the container you can find it under /entrypoint.sh.  
To start without running the entrypoint script, do like this:  
```$ docker run --rm -it -v "$(pwd):/src/" --entrypoint /bin/bash my-pyinstaller-linux```

