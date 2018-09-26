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
         "full" -> connFull(nodeLst, 0, [])
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

   def connFull(nodeLst, idx, connLst) do
      numNodes = length(nodeLst)
      if (idx >= numNodes) do
         connLst
      else
         connFull(nodeLst, idx + 1, connLst ++ [List.delete_at(nodeLst, idx)])
      end
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
         {:ok, node} = Nde.start(%{:conns => [], :algo => algo, :timesHeard => 0, :timesSent => 0, :rumor => "", :done? => 0, :nodeId => numNodes, :s => numNodes, :w => 1, :sToWOld => 1000000,
          :delta1 => 99.99999, :delta2 => 99.99999})
         spawnNodes([node | nodeLst], numNodes - 1, topo, algo)
      end
   end

   def getState() do
      GenServer.call(__MODULE__, :status)
   end

   def checkAllDone(workerLst) do
      if (!Enum.all?(workerLst, fn(workerPid) -> Nde.done?(workerPid) == 1 end)) do
         checkAllDone(workerLst)
      end 
   end

   def startGossiping(state) do
      workerPid = Enum.random(state.workerLst)
      Nde.setRumor(workerPid, state.rumor)
      Enum.map(state.workerLst, fn(workerPid) -> Nde.startGossip(workerPid) end)
      checkAllDone(state.workerLst)
      Nde.getState(Enum.at(state.workerLst, 0)) |> IO.inspect
      Nde.getState(Enum.at(state.workerLst, 1)) |> IO.inspect
      Nde.getState(Enum.at(state.workerLst, 2)) |> IO.inspect
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

   def setRumor(pid, rumor) do
      GenServer.cast(pid, {:setRumor, rumor})
   end

   def startGossip(pid) do
      GenServer.cast(pid, :startAlgo)
   end

   def incTimesSent(pid) do
      GenServer.cast(pid, :incTimesSent)
   end

   def done?(pid) do
      GenServer.call(pid, :done?)
   end

   def setDone(pid) do
      GenServer.cast(pid, :setDone)
   end

   def checkDone(pid, state) do
      if (state.algo == "gossip") do
         if(state.timesSent >= 10) do
            setDone(pid)
            true
         else
            false
         end
      else
         if (state.algo == "push-sum") do
            if(state.delta1 == 99.99999) do
               updateDelta1(pid, (state.s / state.w) - state.sToWOld)
            else 
               if (state.delta2 == 99.99999) do
                  updateDelta2(pid, (state.s / state.w) - state.sToWOld)
                  IO.inspect((state.s / state.w) - state.sToWOld)
               else
                  if ((abs(state.delta1) < 1.0e-10) and (abs(state.delta2) < 1.0e-10) and (abs((state.s / state.w) - state.sToWOld) < 1.0e-10)) do
                     setDone(pid)
                     true
                  else
                     updateDelta1(pid, 99.99999)
                     updateDelta2(pid, 99.99999)
                  end
               end    
            end
         end
      end
   end
   
   def updateSw(pid) do
      GenServer.cast(pid, :updateSw)
   end

   def updateDelta1(pid, val) do
      GenServer.cast(pid, {:updateDelta1, val})
   end

   def updateDelta2(pid, val) do
      GenServer.cast(pid, {:updateDelta2, val})
   end

   def updateSToWOld(pid) do
      GenServer.cast(pid, :updateSToWOld)
   end

   def sendMsg(pid, state) do      
      if ((state.algo == "gossip") and (state.rumor != "") and state.timesSent < 10) do
         :timer.sleep(Enum.random(0..500))
         #send message to a random neighbor
         receiveMsg(Enum.random(state.conns), state.rumor)
         incTimesSent(pid)
      else
         if (state.algo == "push-sum") do
            :timer.sleep(Enum.random(0..500))
            receiveMsg(Enum.random(state.conns), {state.s/2, state.w/2})
            updateSToWOld(pid)
            updateSw(pid)
            incTimesSent(pid)
         end
      end
      checkDone(pid, state)
      sendMsg(pid, getState(pid))
   end

   def receiveMsg(pid, msg) do
      GenServer.cast(pid, {:msg, msg})
   end

   def handle_call(op, _from, state) do
      case op do
         :status -> {:reply, state, state}
         :getConns -> {:reply, state.conns, state}
         :done? -> {:reply, state.done?, state}
         _ -> {:stop, "Not implemented", state}
      end
   end

   def handle_cast(:startAlgo, state) do
      IO.inspect(self())
      Task.async(Nde, :sendMsg, [self(), state])
      {:noreply, state}
   end

   def handle_cast({:msg, msg}, state) do
      IO.inspect(self())
      IO.inspect(state)
      IO.puts(" ")
      if (state.algo == "gossip") do
         {:noreply, %{state | :rumor => msg, :timesHeard => state.timesHeard + 1}}
      else
         {:noreply, %{state | :s => elem(msg, 0) + state.s, :w => elem(msg, 1) + state.w, :timesHeard => state.timesHeard + 1}}
      end
   end

   def handle_cast(op, state)  do
      case op do
         :incTimesSent -> {:noreply, %{state | :timesSent => state.timesSent + 1}}
         :updateSToWOld -> {:noreply, %{state | :sToWOld => state.s / state.w}}
         :updateSw -> {:noreply, %{state | :s => state.s / 2, :w => state.w / 2}}
         {:updateDelta1, val} -> {:noreply, %{state | :delta1 => val}}
         {:updateDelta2, val} -> {:noreply, %{state | :delta2 => val}}
         :setDone -> {:noreply, %{state | :done? => 1}}
         {:setConns, connLst} -> {:noreply, %{state | :conns => connLst}}
         #{:msg, msg} -> {:noreply, %{state | :rumor => msg, :timesHeard => state.timesHeard + 1}}
         {:setRumor, rumor} -> {:noreply, %{state | :rumor => rumor}}
         _ -> {:stop, "Not implemented", state}
      end
   end

end


[numNodes, topology, algorithm] = System.argv     #get command line arguments
Boss.start(%{:numNodes => String.to_integer(numNodes), :topo => topology, :algo => algorithm, :workerLst => [], :rumor => "gossip"})
bossState = Boss.getState()
Boss.startGossiping(bossState)
#Boss.spawnNodes([], 4) |> IO.inspect
#Boss.nearestCube(10, 1) |> IO.inspect
#{:ok, pid} = Nde.start(%{:conns => []})
#Nde.getState(pid) |> IO.inspect
#Nde.setConns(pid, [1, 2, 3, 4]) |> IO.inspect
#Nde.getConns(pid) |> IO.inspect
#Nde.getState(pid) |> IO.inspect
#Boss.connLine([1, 2, 3, 4, 5], 0, []) |> IO.inspect
#Boss.connFull([1, 2, 3, 4, 5], 0, []) |> IO.inspect
