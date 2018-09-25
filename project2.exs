defmodule Boss do
   use GenServer

   def start(state) do
      GenServer.start(Boss, state, name: __MODULE__)
   end

   def init(state) do
      #start numNode nodes 
      workerLst = spawnNodes([], correctedNumNodes(state.numNodes, state.topo), state.topo, state.algo)
      connLst = createConnLst(state.topo, workerLst)
      setConnNodes(connLst, workerLst)
      {:ok, %{state | :workerLst => workerLst}}
   end

   def setConnNodes(connLst, workerLst) do
      if (length(connLst) > 0) do
         [headConn | tailConn] = connLst
         [headWorker | tailWorker] = workerLst
         Nde.setConns(headWorker, headConn)
         setConnNodes(tailConn, tailWorker)
      end
   end

   def correctedNumNodes(numNodes, topo) do
      case topo do
         "full" -> numNodes
         "3D" -> nearestCube(numNodes, 1)
         "rand2D" -> nearestSquare(numNodes, 1)
         "torus" -> nearestSquare(numNodes, 1)
         "line" -> numNodes
         "imp2D" -> nearestSquare(numNodes, 1)
         _ -> {:stop, "Not implemented"}
      end
   end

   def createConnLst(topo, nodeLst) do
      case topo do
         "line" -> connLine(nodeLst, 0, [])
         _-> {:stop, "Not implemented"}
      end
   end

   def connLine(nodeLst, idx, connLst) do
      numNodes = Enum.count(nodeLst)
      if (idx >= numNodes) or (numNodes <= 1) do
         connLst
      else
         if (idx == 0) do
            connLine(nodeLst, idx + 1, connLst ++ [[Enum.at(nodeLst, idx + 1)]])        #node at beginning of line
         else
            if (idx < numNodes - 1) do
               connLine(nodeLst, idx + 1, connLst ++ [[Enum.at(nodeLst, idx - 1), Enum.at(nodeLst, idx + 1)]])  #node in middle of line
            else
               connLine(nodeLst, idx + 1, connLst ++ [[Enum.at(nodeLst, idx - 1)]])          #node at end of line
            end
         end
      end
   end

   def setWorkerConns(connLst, workerLst) do
       IO.puts("setWorkerConns")
       IO.inspect(connLst)
       IO.inspect(workerLst)
       #Enum.map(0..(connLst.size() - 1), fn(x) -> Nde.setConns(Enum.at(workerLst, x), Enum.at(connLst, x)) end) |> IO.inpsect
       IO.puts("setWorkercons Done")
   end

   def nearestSquare(num, sqr) do
       if (num <= sqr * sqr) do
          sqr * sqr
       else
          nearestSquare(num, sqr + 1)
       end
   end

   def nearestCube(num, cube) do
      if (num <= cube * cube * cube) do
         cube * cube * cube
      else
         nearestCube(num, cube + 1)
      end
   end
   
   def spawnNodes(nodeLst, numNodes, topo, algo) do
      if (numNodes == 0) do
         nodeLst
      else
         {:ok, node} = Nde.start(%{:conns => [], :algo => algo, :timesHeard => 0, :rumor => ""})
         spawnNodes([node | nodeLst], numNodes - 1, topo, algo)
      end
   end

   def getState() do
      GenServer.call(__MODULE__, :status)
   end

   def handle_call(op, _from, state) do
      case op do
         :status -> {:reply, state, state}
         _ -> {:stop, "Not implemented", state}
      end
   end

   def handle_cast(op, state)  do
      case op do
         _ -> {:stop, "Not implemented", state}
      end
   end

end

defmodule Nde do
   use GenServer

   def start(init) do
      GenServer.start_link(__MODULE__, init)
   end

   def init(initVal) do
      {:ok, initVal}
   end

   def setConns(pid, connLst) do
      GenServer.cast(pid, {:setConns, connLst})
   end

   def getConns(pid) do
      GenServer.call(pid, :getConns)
   end

   def getState(pid) do
      GenServer.call(pid, :status)
   end

   def startWorking(pid, state) do
      if (state.algo == "gossip") do
         :timer.sleep(Enum.random(0..500))
         Enum.at(state.conns, Enum.random(0..length(state.conns) - 1))
      end
   end

   def handle_call(op, _from, state) do
      case op do
         :status -> {:reply, state, state}
         :getConns -> {:reply, state.conns, state}
         _ -> {:stop, "Not implemented", state}
      end
   end


   def handle_cast(op, state)  do
      case op do
         {:setConns, connLst} -> {:noreply, %{state | :conns => connLst}}
         :startWorking -> {:noreply, state}
         {:msg, msg} -> {:noreply, %{state | :rumor => msg, :timesHeard => state.timesHeard + 1}}
         _ -> {:stop, "Not implemented", state}
      end
   end

end


[numNodes, topology, algorithm] = System.argv     #get command line arguments
Boss.start(%{:numNodes => String.to_integer(numNodes), :topo => topology, :algo => algorithm, :workerLst => []})
Boss.getState() |> IO.inspect
#Boss.spawnNodes([], 4) |> IO.inspect
#Boss.nearestCube(10, 1) |> IO.inspect
#{:ok, pid} = Nde.start(%{:conns => []})
#Nde.getState(pid) |> IO.inspect
#Nde.setConns(pid, [1, 2, 3, 4]) |> IO.inspect
#Nde.getConns(pid) |> IO.inspect
#Nde.getState(pid) |> IO.inspect
#Boss.connLine([1, 2, 3, 4, 5], 0, []) |> IO.inspect
