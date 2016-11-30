wifi.setmode(wifi.STATION);
wifi.sta.config("ssid" ,"pwd");
wifi.sta.sethostname("dht22")
apikey = "somekey"
dofile ("config.lua")

GPIO0 = 3
GPIO2 = 4

-- GPIO0 used as a power source for dht22.
-- this is so deep sleep keeps power usage low.
gpio.mode(GPIO0, gpio.OUTPUT)
gpio.write(GPIO0, gpio.HIGH)

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

        print( "Reading temperature..." )
        status, temp, humi, temp_dec, humi_dec = dht.read(GPIO2)
        if status == dht.OK then
            print("Temperature:"..temp..".".. temp_dec ..";".."Humidity:"..humi.. "." .. humi_dec)
        elseif status == dht.ERROR_CHECKSUM then
            print( "DHT Checksum error." )
        elseif status == dht.ERROR_TIMEOUT then
            print( "DHT Timeout." )
        end
        -- removing power from the dht22, no need for it at this point.
        gpio.write(GPIO0, gpio.LOW)

        -- prevent odd 0.-2 values.
        if (temp == 0 and temp_dec<0) then
           temp = "-"..temp
        end

        connout:send("GET /update?api_key=" .. apikey
        .. "&field1=" .. (volt/1000) .. "." .. (volt%1000)
        .. "&field2=" .. temp .. "." .. math.abs(temp_dec)
        .. "&field3=" .. humi .. "." .. humi_dec
        .. " HTTP/1.1\r\n"
        .. "Host: api.thingspeak.com\r\n"
        .. "Connection: close\r\n"
        .. "Accept: */*\r\n"
        .. "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
        .. "\r\n")
    end)
 
    connout:on("disconnection", function(connout, payloadout)
        connout:close();
        -- normally you would do a collectgarbage() but considering we do dsleep it will reset anyway.
        node.dsleep(600000000) -- 10min
    end)
 
    connout:connect(80,'api.thingspeak.com')
end

postThingSpeak()

