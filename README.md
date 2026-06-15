# DJI Flight Record Parsing

Flight record parsing library can parse version 14 flight log files. Convert DJI protocol data into time frame objects for presentation and analysis. An App Key is required to run the flight record parsing library.

## Credit

This repo is a fork of [FlightRecord](https://github.com/dji-sdk/FlightRecordParsingLib/tree/master) by [DJI SDK](https://developer.dji.com).

## How to use

### Running the sample in Docker
**Get docker** 

https://docs.docker.com/get-docker

**Build docker image**
```shell
docker build --build-arg SDK_KEY=your_app_key -t pf .
```

**Docker run**
```shell
docker run -v host_dir:container_dir pf "container_flight_record_dir"
```
Sample code：
docker run -v $(pwd):/tmp pf "/tmp/V132_DJIFlightRecord_2020-06-18_[19-01-24].txt" > json_result.json

"> json_result.json" Redirecting the running result to a specified file

## How to apply for my App Key?
1. Log in to the [DJI Developer Technologies](https://developer.dji.com/user), click "CREATE APP", select "Open API" for App Type, fill in the "App Name", "Category" and "Description" by yourself, and click "CREATE".

2. Activate the App through your personal email. After activation, click on the corresponding App information on your developer user page. The App Key is the SDK key parameter you need for the next steps.

## Error Codes

If an error occurs during the flight record files parsing, you can solve the problem according to the returned value. The table below shows returned values and error descriptions. Returned value 0 indicates successful parsing.

<table align="center">
  <thead>
    <tr>
      <th>Error Code</th>
      <th>Error Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
        <td>1</td>
        <td>Illegal input parameter</td>
    </tr>
    <tr>
        <td>2</td>
        <td>Illegal flight record file content</td>
    </tr>
    <tr>
        <td>3</td>
        <td>Unsupported flight record file version</td>
    </tr>
    <tr>
        <td>4</td>
        <td>The flight record parser does not exist</td>
    </tr>
    <tr>
        <td>5</td>
        <td>The flight record file includes unsupported functions</td>
    </tr>
    <tr>
        <td>6</td>
        <td>Parsing failed due to message loss</td>
    </tr>
    <tr>
        <td>7</td>
        <td>File operation failed</td>
    </tr>
    <tr>
        <td>8</td>
        <td>Invalid data. The file might be modified </td>
    </tr>
    <tr>
        <td>9</td>
        <td>Data filling failed. Unsupported data filling types</td>
    </tr>
    <tr>
        <td>255</td>
        <td>Unknown error</td>
    </tr>
   </tbody>
</table>



## Architectural relationship

![](images/architectural.png)

* FRSample: Used to introduce how to call interfaces and parse data
* FlightRecordStandardizationCpp: Used to convert C++ structure objects into Protobuf objects for cross-platform data transfer
* FlightRecordStandardization: Used to record the raw data in 10 HZ, and present a view model of aircraft status
* FlightRecordEngine: Used to parse cryptographic data to plaintext data
* libtomcrypt/libtommath: Used to decrypt original documents
* curl/openssl: Used to communicate with DJIService to get the decryption key

### Folder structure

Here is an introduction to the role of file directories：

* build: A common cmake file used in both the engine and kit subdirectories, and a build script
* dji-flightrecord-engine/source: Source code for the dji-flightrecordengine library
* dji-flightrecord-kit/protoc: Protobuf files that house standardized data structures and can be used for cross-platform data transfer
* dji-flightrecord-kit/source: Source code for the dji-flightrecord-kit library
* images：Photo resources cited in README
