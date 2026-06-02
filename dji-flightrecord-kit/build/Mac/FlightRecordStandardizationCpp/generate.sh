platform="Mac"
sourceFolder="../../../source/FlightRecordStandardizationCpp"

echo "Which do you want to build? Please Input the number: "

read -p "0: Libray 1: Project        input: " operation
generate.sh
if [ $operation == '0' ]
then
    cmake -D platform=${platform} ${sourceFolder}
    make
elif [ $operation == '1' ]
then
    echo "Start generate the project"
    cmake -D platform=${platform} -G "Xcode" ${sourceFolder}
else
    echo "without any operation"
fi