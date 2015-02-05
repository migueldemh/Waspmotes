
#include <WaspXBeeZB.h>
#include <WaspFrame.h>
#include <WaspSensorAgr_v20.h>

// Pointer an XBee packet structure 
packetXBee* packet; 

// Destination MAC address
char* MAC_ADDRESS="0013A2004081DBFA";

// Node identifier
char* NODE_ID="Mota";

// Sleeping time DD:hh:mm:ss
char* sleepTime = "00:00:00:10";    

// Sensor variables
float TemperatureFloatValue;
float HumidityFloatValue;
float PressureFloatValue;
float LuminityFloatValue;
//float soilMoistureFloatValue;

// retries counter
int retries=0;

// maximum number of retries when sending
#define MAX_RETRIES 3


void setup()
{
  // 0. Init USB port for debugging
  USB.ON();
  USB.println(F("Comenzamos..."));


  ////////////////////////////////////////////////
  // 1. Initial message composition
  ////////////////////////////////////////////////

  // 1.1 Set mote Identifier (16-Byte max)
  frame.setID(NODE_ID);	

  // 1.2 Create new frame
  frame.createFrame(ASCII, "WASPMOTE");  

  // 1.3 Set frame fields (String - char*)
  frame.addSensor(SENSOR_STR,"MotaUPM");

  // 1.4 Print frame
 // frame.showFrame();


  ////////////////////////////////////////////////
  // 2. Send initial message
  ////////////////////////////////////////////////

  // 2.1 Switch on the XBee module
  xbeeZB.ON(); 
    xbeeZB.wake();
  delay(2000); 
  //////////////////////////
  // 2. check XBee's network parameters
  //////////////////////////
  checkNetworkParams();

  // 2.2 Memory allocation
  packet = (packetXBee*) calloc(1,sizeof(packetXBee));

  // 2.3 Choose transmission mode: UNICAST or BROADCAST
  packet->mode = UNICAST;
 
  // 2.4 Set destination XBee parameters to packet
  xbeeZB.setDestinationParams(packet, MAC_ADDRESS, frame.buffer, frame.length); 

  // 2.5 Initial message transmission
  xbeeZB.sendXBee(packet);

  // 2.6 Check TX flag
  if ( xbeeZB.error_TX == 0 ) 
  {
    USB.println(F("ok"));
     USB.print("sleep mode:");
  USB.println(xbeeZB.sleepMode,HEX);
  }
  else 
  {
    USB.println(F("error"));
     USB.print("sleep mode:");
  USB.println(xbeeZB.sleepMode,HEX);
  }

  // 2.7 Free memory
  free(packet);
  packet=NULL;

  // 2.8 Communication module to OFF
  xbeeZB.OFF();
  delay(100);

}

void loop()
{

  ////////////////////////////////////////////////
  // 3. Measure corresponding values
  ////////////////////////////////////////////////
  USB.println(F("Measuring sensors..."));

  // 3.1 Turn on the sensor board
  SensorAgrv20.ON();

  // 3.2 Turn on the RTC
  RTC.ON();
  RTC.getTime(); 

  // 3.3 Supply stabilization delay
  delay(100);

  // 3.4 Turn on the sensors
  SensorAgrv20.setSensorMode(SENS_ON, SENS_AGR_TEMPERATURE);
    SensorAgrv20.setSensorMode(SENS_ON, SENS_AGR_HUMIDITY);
      SensorAgrv20.setSensorMode(SENS_ON, SENS_AGR_PRESSURE);
SensorAgrv20.setSensorMode(SENS_ON, SENS_AGR_LDR);

  //delay(100);
  //SensorAgrv20.setSensorMode(SENS_ON, SENS_AGR_WATERMARK_1);
  delay(1000);

  // 3.5 Sensor temperature reading
  TemperatureFloatValue = SensorAgrv20.readValue(SENS_AGR_TEMPERATURE);
HumidityFloatValue=SensorAgrv20.readValue(SENS_AGR_HUMIDITY);
  PressureFloatValue=SensorAgrv20.readValue(SENS_AGR_PRESSURE);
LuminityFloatValue=SensorAgrv20.readValue(SENS_AGR_LDR);

  // 3.6 Sensor moisture reading
  //soilMoistureFloatValue = SensorAgrv20.readValue(SENS_AGR_WATERMARK_1);

  // 3.7 Turn off the sensors
  SensorAgrv20.setSensorMode(SENS_OFF, SENS_AGR_TEMPERATURE);
    SensorAgrv20.setSensorMode(SENS_OFF, SENS_AGR_HUMIDITY);
  SensorAgrv20.setSensorMode(SENS_OFF, SENS_AGR_PRESSURE);
SensorAgrv20.setSensorMode(SENS_OFF, SENS_AGR_LDR);
  //SensorAgrv20.setSensorMode(SENS_OFF, SENS_AGR_WATERMARK_1);
 
 // Print the temperature value through the USB
  USB.print(F("Temperature: "));
  USB.print(TemperatureFloatValue);
  USB.println(F("ºC"));
 // Print the humidity value through the USB
  USB.print(F("Humidity: "));
  USB.print(HumidityFloatValue);
  USB.println(F("%RH"));
  // Print the pressure value through the USB
  USB.print(F("Pressure: "));
  USB.print(PressureFloatValue);
  USB.println(F("kPa"));
    // Print the LDR value through the USB
  USB.print(F("Luminosity: "));
  USB.print(LuminityFloatValue);
  USB.println(F("V"));
  ////////////////////////////////////////////////
  // 4. Message composition
  ////////////////////////////////////////////////

  // 4.1 Create new frame
  frame.createFrame();  

  // 4.2 Add frame fields
  frame.addSensor(SENSOR_TCA, TemperatureFloatValue ); 
  frame.addSensor(SENSOR_HUMA, HumidityFloatValue );
    frame.addSensor(SENSOR_PA, PressureFloatValue );
    frame.addSensor(SENSOR_LUM, LuminityFloatValue );

  //frame.addSensor(SENSOR_SOIL, soilMoistureFloatValue);   
  //frame.addSensor(SENSOR_TIME, RTC.hour, RTC.minute, RTC.second );  
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel() );

  // 4.3 Print frame
  // Example: <=>#35689511#N01#1#SOILT:25.91#SOIL:4424.77#TIME:16-0-59#BAT:78#
  frame.showFrame();


  ////////////////////////////////////////////////
  // 5. Send message
  ////////////////////////////////////////////////

  // 5.1 Switch on the XBee module
  xbeeZB.ON();
    xbeeZB.wake();
  delay(2000);  

  // 5.2 Set parameters to packet:
  packet=(packetXBee*) calloc(1,sizeof(packetXBee)); // Memory allocation
  packet->mode=UNICAST; // Choose transmission mode: UNICAST or BROADCAST

    // 5.3 Set destination XBee parameters to packet
  xbeeZB.setDestinationParams(packet, MAC_ADDRESS, frame.buffer, frame.length); 

  // 5.4 Send XBee packet
  xbeeZB.sendXBee(packet);

  // 5.5 retry sending if necessary for a maximum of MAX_RETRIES
  retries=0;
  while( xbeeZB.error_TX != 0 ) 
  {
    if( retries >= MAX_RETRIES )
    {
      break;
    }
    
    retries++;
    delay(1000);
    xbeeZB.sendXBee(packet);          
  }

  // 5.6. check TX flag
  if( xbeeZB.error_TX == 0 )
  {
    USB.println(F("OK"));
     USB.print("sleep mode:");
  USB.println(xbeeZB.sleepMode,HEX);
  }
  else
  {
        USB.println(F("ERROR"));
     USB.print("sleep mode:");
  USB.println(xbeeZB.sleepMode,HEX);
  }

  // 5.7 Free memory
  free(packet);
  packet = NULL;

  // 5.8 Communication module to OFF
  xbeeZB.OFF();



  ////////////////////////////////////////////////
  // 6. Entering Deep Sleep mode
  ////////////////////////////////////////////////
  USB.println(F("Going to sleep..."));
  USB.println();
    delay(100);
  //PWR.deepSleep(sleepTime, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}




/*******************************************
 *
 *  checkNetworkParams - Check operating
 *  network parameters in the XBee module
 *
 *******************************************/
void checkNetworkParams()
{
  // 1. get operating 64-b PAN ID
  xbeeZB.getOperating64PAN();

  // 2. wait for association indication
  xbeeZB.getAssociationIndication();
 
  while( xbeeZB.associationIndication != 0 )
  { 
    delay(2000);
    
    // get operating 64-b PAN ID
    xbeeZB.getOperating64PAN();

    USB.print(F("operating 64-b PAN ID: "));
    USB.printHex(xbeeZB.operating64PAN[0]);
    USB.printHex(xbeeZB.operating64PAN[1]);
    USB.printHex(xbeeZB.operating64PAN[2]);
    USB.printHex(xbeeZB.operating64PAN[3]);
    USB.printHex(xbeeZB.operating64PAN[4]);
    USB.printHex(xbeeZB.operating64PAN[5]);
    USB.printHex(xbeeZB.operating64PAN[6]);
    USB.printHex(xbeeZB.operating64PAN[7]);
    USB.println();     
    
    xbeeZB.getAssociationIndication();
  }

  USB.println(F("\nJoined a network!"));

  // 3. get network parameters 
  xbeeZB.getOperating16PAN();
  xbeeZB.getOperating64PAN();
  xbeeZB.getChannel();

  USB.print(F("operating 16-b PAN ID: "));
  USB.printHex(xbeeZB.operating16PAN[0]);
  USB.printHex(xbeeZB.operating16PAN[1]);
  USB.println();

  USB.print(F("operating 64-b PAN ID: "));
  USB.printHex(xbeeZB.operating64PAN[0]);
  USB.printHex(xbeeZB.operating64PAN[1]);
  USB.printHex(xbeeZB.operating64PAN[2]);
  USB.printHex(xbeeZB.operating64PAN[3]);
  USB.printHex(xbeeZB.operating64PAN[4]);
  USB.printHex(xbeeZB.operating64PAN[5]);
  USB.printHex(xbeeZB.operating64PAN[6]);
  USB.printHex(xbeeZB.operating64PAN[7]);
  USB.println();

  USB.print(F("channel: "));
  USB.printHex(xbeeZB.channel);
  USB.println();

}
