# Event Hub Streaming Data Simulator
Simulate live streaming data using your own data. 
This implementation works with a csv file as source, and hits an Azure Event Hub, one line at a time. Built using Powershell (PS1). 
It can easily be adjusted for different file types and different Azure components (such as IoT Hub).

## How To
1. Create an Event Hub in your Azure portal
2. Create an access policy (read, write)
3. Insert the access policy details (name and key), as well as the Event Hub URI, into the appropriate placeholders in the powershell script
4. Update the source folder of your file
5. Optional: update the timer and the number of loops, depending on your needs. 
Bonus:
6. Attach the Event Hub to a Azure Stream Analytics job. Now you can process your simulated data, score it using an Azure Machine Learning web service, or simply process it and store it, or visualize the streaming feed using PowerBI. See the resources below for more information.

## Additional Resources
# Event Hub Powershell Module
https://www.powershellgallery.com/packages/Azure.EventHub/0.9.0
# Process streaming data using Azure Stream Analytics
https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-get-started-with-azure-stream-analytics-to-process-data-from-iot-devices 
# Display live streaming data in PowerBI
https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-power-bi-dashboard 

## Credits
The authentication and connection functions were written as a PS1 module by Marcel Meurer. His implementation can be found here: https://www.powershellgallery.com/packages/Azure.EventHub/0.9.0