*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Keywords ***
Create Necessary Folders
    Create Directory    ${OUTPUT_DIR}${/}ReceiptsPDFs
    Create Directory    ${OUTPUT_DIR}${/}RobotScreenshots
    Create Directory    ${OUTPUT_DIR}${/}OrderPDFs
    Create Directory    ${OUTPUT_DIR}${/}Output

Open the robot order website
    ${vault_data}=    Get Secret    credentials
    Open Available Browser    ${vault_data}[url]    maximized=True

Get CSV URL from User and Download CSV and Get Orders
    Add text input    name=url    label= Enter the URL of CSV file
    ${dialog}=    Show dialog    title=Input form
    ${result}=    Wait dialog    ${dialog}
    Download    ${result.url}
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    #element exist
    Click Button    OK
    #Click Element    locator

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    //html/body/div[1]/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    Preview
    Click Button    Order

Check Robot Order Status
    [Arguments]    ${row}
    &{isOrderAnotherBotExist}    Get Element Status    id:order-another
    IF    ${isOrderAnotherBotExist.visible} == True
        Log To Console    ${isOrderAnotherBotExist.visible}
        #Store the order receipt as a PDF file
        ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}ReceiptsPDFs${/}${row}[Order number].pdf
        #Take a screenshot of the robot image
        Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}RobotScreenshots${/}${row}[Order number].png
        #Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/subdir/${row}[Order number].png
        #Add Files To Pdf
        ${FilesToAppend}=    Create List    ${OUTPUT_DIR}${/}ReceiptsPDFs${/}${row}[Order number].pdf
        ...    ${OUTPUT_DIR}${/}RobotScreenshots${/}${row}[Order number].png
        Add Files To Pdf    ${FilesToAppend}    ${OUTPUT_DIR}${/}OrderPDFs${/}${row}[Order number].pdf
        Click Element    id:order-another
        Close the annoying modal
    ELSE
        Click Button    Preview
        Click Button    Order
        Check Robot Order Status    ${row}
    END

Close the browser
    Close Browser

Create Zip File
    Archive Folder With Zip    ${OUTPUT_DIR}${/}OrderPDFs    ${OUTPUT_DIR}${/}Output${/}OrderPDFs.zip

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Create Necessary Folders
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get CSV URL from User and Download CSV and Get Orders
    FOR    ${row}    IN    @{orders}
        Log To Console    ${row}[Order number]
        Log To Console    ${1}
        Fill the form    ${row}
        Check Robot Order Status    ${row}
    END
    Create Zip File
    [Teardown]    Close the browser
    Log To Console    Done
