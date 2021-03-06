defmodule Boss do
   use GenServer

   def start(state) do
      GenServer.start(Boss, state, name: __MODULE__)
   end

   def init(state) do
      #start numNode nodes 
      workerLst = spawnNodes([], correctedNumNodes(state.numNodes, state.topo), state.topo, state.algo, state.fRate)
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
         "imp2D" -> connLineImp(nodeLst, 0, [])
         "torus" -> connTorus(nodeLst)
         "3D" -> conn3D(nodeLst)
         "rand2D" -> connRand2D(nodeLst)
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

   def connLineImp(nodeLst, idx, connLst) do
      numNodes = Enum.count(nodeLst)
      if (idx >= numNodes) or (numNodes <= 1) do
         connLst
      else
         if (idx == 0) do
            tempLst = List.delete_at(nodeLst, idx) |> List.delete(Enum.at(nodeLst, idx + 1))
            connLineImp(nodeLst, idx + 1, connLst ++ [[Enum.at(nodeLst, idx + 1), Enum.random(tempLst)]])        #node at beginning of line
         else
            if (idx < numNodes - 1) do
               tempLst = List.delete_at(nodeLst, idx) |> List.delete(Enum.at(nodeLst, idx - 1)) |> List.delete(Enum.at(nodeLst, idx + 1))
               connLineImp(nodeLst, idx + 1, connLst ++ [[Enum.at(nodeLst, idx - 1), Enum.at(nodeLst, idx + 1), Enum.random(tempLst)]])  #node in middle of line
            else
               tempLst = List.delete_at(nodeLst, idx) |> List.delete(Enum.at(nodeLst, idx - 1))
               connLineImp(nodeLst, idx + 1, connLst ++ [[Enum.at(nodeLst, idx - 1), Enum.random(tempLst)]])          #node at end of line
            end
         end
      end
   end

   def mod(val, base) do
      if (val < 0) do
         rem(val, base) + base
      else
         rem(val, base)
      end   
   end

   def getGridNeighbors2D(gridPos, gridMap, lenSide) do
      connLst = []
      connLst = [gridMap[{mod(elem(gridPos, 0) + 1, lenSide), elem(gridPos, 1)}] | connLst]
      #IO.inspect({mod(elem(gridPos, 0) + 1, lenSide), elem(gridPos, 1)})
      #IO.gets("pause")


      connLst = [gridMap[{mod(elem(gridPos, 0) - 1, lenSide), elem(gridPos, 1)}] | connLst]
      #IO.inspect({mod(elem(gridPos, 0) - 1, lenSide), elem(gridPos, 1)})
      #IO.gets("pause")

      connLst = [gridMap[{elem(gridPos, 0), mod(elem(gridPos, 1) - 1, lenSide)}] | connLst]
    
      connLst = [gridMap[{elem(gridPos, 0), mod(elem(gridPos, 1) + 1, lenSide)}] | connLst]
      
      connLst 
   end

   def getGridNeighbors3D(gridPos, gridMap) do
      connLst = []

      #IO.inspect(gridMap[{elem(gridPos, 0) + 1, elem(gridPos, 1), elem(gridPos, 2)}])
      #IO.gets("pause")
      connLst = [gridMap[{elem(gridPos, 0) + 1, elem(gridPos, 1), elem(gridPos, 2)}] | connLst]
      #IO.puts("A")
      #IO.inspect(connLst)
      connLst = [gridMap[{elem(gridPos, 0) - 1, elem(gridPos, 1), elem(gridPos, 2)}] | connLst]
      connLst = [gridMap[{elem(gridPos, 0), elem(gridPos, 1) + 1, elem(gridPos, 2)}] | connLst]
      connLst = [gridMap[{elem(gridPos, 0), elem(gridPos, 1) - 1, elem(gridPos, 2)}] | connLst]
      connLst = [gridMap[{elem(gridPos, 0), elem(gridPos, 1), elem(gridPos, 2) + 1}] | connLst]
      connLst = [gridMap[{elem(gridPos, 0), elem(gridPos, 1), elem(gridPos, 2) - 1}] | connLst]
      #IO.puts("B") 
      Enum.filter(connLst, fn(x) -> x != nil end) #|> IO.inspect
      #IO.gets("pause")

   end

   def connTorus(nodeLst) do
      lenSide = round(:math.sqrt(length(nodeLst)))
      #IO.inspect(nodeLst)
      #IO.inspect(lenSide)
      gridSqrs = Enum.map(0..lenSide-1, fn(x) -> Enum.map(0..lenSide-1, fn(y) -> {x, y} end) end) |> List.flatten()
      #IO.inspect(gridSqrs)
      gridMap = Enum.zip(gridSqrs, nodeLst) |> Enum.into(%{})
      #IO.inspect(gridMap)
      connLst = Enum.map(gridSqrs, fn(pos) -> getGridNeighbors2D(pos, gridMap, lenSide) end)
      connLst      
      #IO.inspect(connLst)
      #IO.gets("pause")
   end

   def conn3D (nodeLst) do
      lenSide = round(:math.pow(length(nodeLst), (1/3)))
      #IO.inspect(lenSide)

      gridSqrs = Enum.map(0..(lenSide - 1), fn(x) -> Enum.map(0..(lenSide - 1), fn(y) -> Enum.map(0..(lenSide - 1), fn(z) -> {x, y, z} end) end) end) |> List.flatten()
      #IO.inspect(gridSqrs)

      gridMap = Enum.zip(gridSqrs, nodeLst) |> Enum.into(%{})
      #IO.inspect(gridMap)

      connLst = Enum.map(gridSqrs, fn(pos) -> getGridNeighbors3D(pos, gridMap) end)    
      connLst  
      #IO.inspect(connLst)
      #IO.gets("pause")
   end

   def connFull(nodeLst, idx, connLst) do
      numNodes = length(nodeLst)
      if (idx >= numNodes) do
         connLst
      else
         connFull(nodeLst, idx + 1, connLst ++ [List.delete_at(nodeLst, idx)])
      end
   end

   def dist(pos1, pos2) do
      :math.sqrt(:math.pow(elem(pos2, 1) - elem(pos1, 1), 2) + :math.pow(elem(pos2, 0) - elem(pos1, 0), 2))
   end

   def rand2DgetNeighbors(gridPos, gridMap, gridSqrs) do
      gridSqrs = List.delete(gridSqrs, gridPos)
      connLst = Enum.filter(gridSqrs, fn(pos2) -> dist(gridPos, pos2) <= 0.1 end) |> Enum.map(fn(x) -> gridMap[x] end) 
      connLst
   end

   def connRand2D(nodeLst) do
      xCoords = Enum.map(0..length(nodeLst) - 1, fn(_) -> :rand.uniform() end)
      yCoords = Enum.map(0..length(nodeLst) - 1, fn(_) -> :rand.uniform() end)
      gridSqrs = Enum.zip(xCoords, yCoords)
      gridMap = Enum.zip(gridSqrs, nodeLst) |> Enum.into(%{})
      connLst = Enum.map(gridSqrs, fn(pos) -> rand2DgetNeighbors(pos, gridMap, gridSqrs) end)
      #IO.inspect(gridSqrs)
      #IO.inspect(gridMap)
      #IO.inspect(connLst) 
      #IO.gets("pause")
      connLst
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
   
   def spawnNodes(nodeLst, numNodes, topo, algo, fRate) do
      if (numNodes == 0) do
         nodeLst
      else
         {:ok, node} = Nde.start(%{:conns => [], :algo => algo, :timesHeard => 0, :timesSent => 0, :rumor => "", :done? => 0, :nodeId => numNodes, :s => numNodes, :w => 1, :sToWOld => 1000000,
          :delta1 => 99.99999, :delta2 => 99.99999, :failureRate => fRate})
         spawnNodes([node | nodeLst], numNodes - 1, topo, algo, fRate)
      end
   end

   def getState() do
      GenServer.call(__MODULE__, :status)
   end

   def checkAllDone(workerLst, time1, tMax) do
      deltaTime = (System.monotonic_time(:milliseconds) - time1) / 1000.0
      #IO.inspect(deltaTime)
      if ((!Enum.all?(workerLst, fn(workerPid) -> Nde.done?(workerPid) == 1 end)) and (deltaTime < (tMax * 1.05))) do
         checkAllDone(workerLst, time1, tMax)
      end 
   end

   def startGossiping(state) do
      tMax = 400.0
      workerPid = Enum.random(state.workerLst)
      Nde.setRumor(workerPid, state.rumor)
      Enum.map(state.workerLst, fn(workerPid) -> Nde.startGossip(workerPid) end)
      time1 = System.monotonic_time(:milliseconds)
      checkAllDone(state.workerLst, time1, tMax)
      time2 = System.monotonic_time(:milliseconds)
      deltaT = (time2 - time1) / 1000.0
      #Nde.getState(Enum.at(state.workerLst, 0)) |> IO.inspect
      #Nde.getState(Enum.at(state.workerLst, 1)) |> IO.inspect
      #Nde.getState(Enum.at(state.workerLst, 2)) |> IO.inspect
      
      if (deltaT >= tMax) do
         IO.puts("#{length(state.workerLst)}," <> "NaN")
      else
         IO.puts("#{length(state.workerLst)},#{deltaT}")
      end
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

   def init(initVal) do
      {:ok, initVal}
   end

   def checkDone(pid, state) do
      if (state.algo == "gossip") do
         if ((state.timesSent >= 100) or (state.timesHeard >= 10) or (length(state.conns) == 0) or (state.done? == 1)) do
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
               else
                  if (((abs(state.delta1) < 1.0e-10) and (abs(state.delta2) < 1.0e-10) and (abs((state.s / state.w) - state.sToWOld) < 1.0e-10)) or (length(state.conns) == 0) or (state.done? == 1)) do
                     setDone(pid)
                     true
                  else
                     updateDelta1(pid, 99.99999)
                     updateDelta2(pid, 99.99999)
                     false
                  end
               end    
            end
         end
      end
   end

   def sendMsg(pid, state) do
      pFailure = :rand.uniform(100)      #between [1, 100]
      #if state.fRate = 0, never fails
      if ((state.algo == "gossip") and (state.rumor != "") and (state.done? != 1)) do
         :timer.sleep(Enum.random(0..500))
         #send message to a random neighbor make sure list isn't empty
         if ((length(state.conns) > 0) and (pFailure > state.failureRate))do
            receiveMsg(Enum.random(state.conns), state.rumor)
            incTimesSent(pid)
         end
      else
         if (state.algo == "push-sum") and (state.done? != 1) do
            :timer.sleep(Enum.random(0..500))
            #send message to random neighbor, make sure list isn't empty
            if ((length(state.conns) > 0) and (pFailure > state.failureRate)) do
               receiveMsg(Enum.random(state.conns), {state.s/2, state.w/2})
               incTimesSent(pid)
               updateSToWOld(pid)
               updateSw(pid)
            end
         end
      end
      checkDone(pid, getState(pid))
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
      #IO.inspect(self())
      Task.async(Nde, :sendMsg, [self(), state])
      {:noreply, state}
   end

   def handle_cast({:msg, msg}, state) do
      pFailure = :rand.uniform(100)     #between [1, 100]
      # if state.fRate = 0, never fails
      if (state.algo == "gossip") do
         if (pFailure > state.failureRate) do
            {:noreply, %{state | :rumor => msg, :timesHeard => state.timesHeard + 1}}
         else
            {:noreply, state}
         end
      else
         if (pFailure > state.failureRate) do
            {:noreply, %{state | :s => elem(msg, 0) + state.s, :w => elem(msg, 1) + state.w, :timesHeard => state.timesHeard + 1}}
         else
            {:noreply, state}
         end
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
         {:setRumor, rumor} -> {:noreply, %{state | :rumor => rumor}}
         _ -> {:stop, "Not implemented", state}
      end
   end

end

defmodule ProcessInfo do
   def parseArgs(args) do
      if (length(args) == 3) do
          args ++ ["0"]
      else
         args
      end
   end
end

[numNodes, topology, algorithm, fRate] = ProcessInfo.parseArgs(System.argv)
Boss.start(%{:numNodes => String.to_integer(numNodes), :topo => topology, :algo => algorithm, :workerLst => [], :rumor => "gossip", :fRate => String.to_integer(fRate)})
bossState = Boss.getState()
Boss.startGossiping(bossState)
