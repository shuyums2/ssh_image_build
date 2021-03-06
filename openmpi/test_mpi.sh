docker build -t mpi_img .

export container_main=mpi_main
export container_worker=mpi_worker
export worker_ssh=54321
export output=/tmp/foo.txt

docker rm --force $container_main $container_worker

rm ./main/hostfile
touch ./main/hostfile
echo "0.0.0.0 port=${worker_ssh}" >> ./main/hostfile
# echo "localhost" >> ./main/hostfile

docker run -d -e SSH_PORT=${worker_ssh} \
    --net=host -v /home/x/repo/ssh_image_build/openmpi/main:/main --name ${container_worker} mpi_img
docker run -d \
    --net=host -v /home/x/repo/ssh_image_build/openmpi/main:/main --name ${container_main} mpi_img

docker exec ${container_main} mpirun -v --allow-run-as-root --hostfile /main/hostfile \
    -N 2 \
    --wdir /main \
    -mca plm_rsh_agent /azureml-envs/tensorflow-2.4/bin/python \
    -mca plm_rsh_args /main/agent.py \
    /azureml-envs/tensorflow-2.4/bin/python train.py ${output}


echo "** Checking main ${output} **"
docker exec ${container_main} cat ${output}

echo "** Checking worker ${output} **"
docker exec ${container_worker} cat ${output}
