dofile ("config.lua")

GPIO2 = 4

if adc.force_init_mode(adc.INIT_VDD33)
then
  node.restart()
  return -- don't bother continuing, the restart is scheduled
end

function postThingSpeak()
    connout = nil
    connout = net.createConnection(net.TCP, 0)
 
    connout:on("receive", function(connout, payloadout)
        if (string.find(payloadout, "Status: 200 OK") ~= nil) then
            print("Posted OK");
        end
    end)
 
    connout:on("connection", function(connout, payloadout)
 
        local volt = adc.readvdd33(0);      
        print ("Voltage:" .. volt);

        connout:send("GET /update?api_key=" .. apikey
        .. "&field1=" .. (volt/1000) .. "." .. (volt%1000)
        .. "&field2=" .. counter
        .. " HTTP/1.1\r\n"
        .. "Host: api.thingspeak.com\r\n"
        .. "Connection: close\r\n"
        .. "Accept: */*\r\n"
        .. "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
        .. "\r\n")
    end)
 
    connout:on("disconnection", function(connout, payloadout)
        connout:close();
        collectgarbage()
    end)
 
    connout:connect(80,'api.thingspeak.com')
end

function onChange ()
    gpio.mode(GPIO2, gpio.LOW) -- disable interrupting for a few msec.
    counter = counter+1
    print('Counter '..counter)
    -- a typical pulse will be 50ms so now wait more than that=80ms before allowing the next pulse.
    tmr.register(0, 80, tmr.ALARM_SINGLE, function() 
        gpio.mode(GPIO2, gpio.INT)
        gpio.trig(GPIO2, 'up', onChange)
        end)
    tmr.start(0)
end

counter=0;
gpio.mode(GPIO2, gpio.INT)
gpio.trig(GPIO2, 'up', onChange)

tmr.register(1, 60*1000, tmr.ALARM_AUTO, postThingSpeak)
tmr.start(1)

