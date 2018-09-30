#!/bin/bash

numNodesFull="2 4 8 16 32 64 128 256 512 1024 2048 4096"
numNodes3D="2 4 8 16 32 64 128 256 512 1024 2048 4096"
numNodesrand2D="2 4 8 16 32 64 128 256 512 1024 2048 4096"
numNodesTorus="2 4 8 16 32 64 128 256 512 1024 2048 4096"
numNodesLine="2 4 8 16 32 64 128 256 512 1024 2048 4096"
numNodesImp2D="2 4 8 16 32 64 128 256 512 1024 2048 4096"

topos="full 3D rand2D torus line imp2D"

algos="gossip push-sum"

for algo in $algos
do
 for topo in $topos 
  do
   if [ "$topo" = "full" ]; then
     rm $topo+$algo.csv
     for numNodes in $numNodesFull
      do
       mix run project2.exs $numNodes $topo $algo >> $topo+$algo.csv
       sleep 1s 
      done
   fi

   if [ "$topo" = "3D" ]; then
     rm $topo+$algo.csv
     for numNodes in $numNodesFull
      do
       mix run project2.exs $numNodes $topo $algo >> $topo+$algo.csv
      done
   fi

   if [ "$topo" = "rand2D" ]; then
     rm $topo+$algo.csv
     for numNodes in $numNodesFull
      do
       mix run project2.exs $numNodes $topo $algo >> $topo+$algo.csv
      done
   fi

   if [ "$topo" = "torus" ]; then
     rm $topo+$algo.csv
     for numNodes in $numNodesFull
      do
       mix run project2.exs $numNodes $topo $algo >> $topo+$algo.csv
      done
   fi

   if [ "$topo" = "line" ]; then
     rm $topo+$algo.csv
     for numNodes in $numNodesFull
      do
       mix run project2.exs $numNodes $topo $algo >> $topo+$algo.csv
      done
   fi

   if [ "$topo" = "imp2D" ]; then
     rm $topo+$algo.csv
     for numNodes in $numNodesFull
      do
       mix run project2.exs $numNodes $topo $algo >> $topo+$algo.csv
      done
   fi


  done
done
