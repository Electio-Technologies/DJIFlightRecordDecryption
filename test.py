from frsample import parse_flight_record

result = parse_flight_record("/app/sample-flightlog.txt", sdk_key="da68596deffc654ea56bf68bb56d2bb")
print(result["summary"])
