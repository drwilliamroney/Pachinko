@echo off
set _CONTAINER_PROGRAM=podman
set UBUNTU_VERSION=ubuntu:24.04
set SLURM_VERSION=25.11.0
set SLURM_MD5=b80465f2dd9f763f26fd8f7906b52aa9
set SLURM_NODES=2
set SLURM_NODE_MEM=4096
set SLURM_NET=slurmnet
set SLURM_RUNARGS=--mount type=bind,src="./results",target=/tmp/lab
set SLURM_NODE_RUNARGS=--memory=4g --cpus=2 --mount type=bind,src="./results",target=/tmp/lab
rem MySQL credentials
rem The defaults are only suitable for local development/testing

cd build
echo Building slurm version %SLURM_VERSION% 
echo    MD5: %SLURM_MD5%
echo    using %UBUNTU_VERSION%

%_CONTAINER_PROGRAM% build --build-arg UBUNTU_VERSION=%UBUNTU_VERSION% --build-arg SLURM_VERSION=%SLURM_VERSION% --build-arg SLURM_MD5=%SLURM_MD5% -f Dockerfile.slurm --tag slurm:%SLURM_VERSION% .

cd ..

echo Creating network
%_CONTAINER_PROGRAM% network create %SLURM_NET%

echo Starting Slurm Controller
%_CONTAINER_PROGRAM% run --detach --network %SLURM_NET% -p 6817:6817 %SLURM_RUNARGS% --name slurmctl -h slurmctl slurm:%SLURM_VERSION%  /bin/sh -c "/usr/local/bin/start_controller.sh"

echo Starting Jupyter
%_CONTAINER_PROGRAM% run --detach --network %SLURM_NET% -p 8888:8888 %SLURM_RUNARGS% --name slurmjupyter -h slurmjupyter -e USER=slurm slurm:%SLURM_VERSION%  /bin/sh -c "/usr/local/bin/start_jupyter.sh"

echo Starting Slurm Nodes
%_CONTAINER_PROGRAM% run --detach --network %SLURM_NET% %SLURM_NODE_RUNARGS% --name slurmnode1 -h slurmnode1 slurm:%SLURM_VERSION%  /bin/sh -c "/usr/local/bin/start_node.sh"
%_CONTAINER_PROGRAM% run --detach --network %SLURM_NET% %SLURM_NODE_RUNARGS% --name slurmnode2 -h slurmnode2 slurm:%SLURM_VERSION%  /bin/sh -c "/usr/local/bin/start_node.sh"

goto exit

:exit


