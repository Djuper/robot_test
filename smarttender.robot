# -*- coding: utf-8 -*-
*** Settings ***
Library           String
Library           DateTime
Library           smarttender_service.py
Library           op_robot_tests.tests_files.service_keywords
Library           Selenium2Library

*** Variables ***
${browserAlias}                        'our_browser'
${synchronization}                      http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_SYNCANDMOVE&args=&ticket=&pureJson=
${path to find tender}                  http://test.smarttender.biz/test-tenders/
${find tender field}                    xpath=//input[@placeholder="Введіть запит для пошуку або номер тендеру"]
${tender found}                         xpath=//*[@id="tenders"]/tbody//a[@class="linkSubjTrading"]
${wait}                                 60
${iframe}                               jquery=iframe:eq(0)

#login
${open login button}                    id=LoginAnchor
${login field}                          xpath=(//*[@id="LoginBlock_LoginTb"])[2]
${password field}                       xpath=(//*[@id="LoginBlock_PasswordTb"])[2]
${remember me}                          xpath=(//*[@id="LoginBlock_RememberMe"])[2]
${login button}                         xpath=(//*[@id="LoginBlock_LogInBtn"])[2]

#open procedure
${question_button}                      xpath=//a[@id="question"]

#make proposal
${block}                                xpath=.//*[@class='ivu-card ivu-card-bordered']
${cancellation offers button}           ${block}[last()]//div[@class="ivu-poptip-rel"]/button
${cancel. offers confirm button}        ${block}[last()]//div[@class="ivu-poptip-footer"]/button[2]
${ok button}                            xpath=.//div[@class="ivu-modal-body"]/div[@class="ivu-modal-confirm"]//button
${loading}                              css=#app .smt-load .box

#webclient
${owner change}                         css=[data-name="TBCASE____F4"]
${ok add file}                          jquery=span:Contains('ОК'):eq(0)
${webClient loading}                    id=LoadingPanel
${orenda}                               css=[data-itemkey='438']
${create tender}                        css=[data-name="TBCASE____F7"]
${add file button}                      css=#cpModalMode div[data-name='BTADDATTACHMENT']
${choice file path}                     xpath=//*[@type='file'][1]
${add files tab}                        xpath=//li[contains(@class, 'dxtc-tab')]//span[text()='Завантаження документації']

*** Keywords ***
####################################
#              COMMON              #
####################################
Підготувати клієнт для користувача
    [Arguments]  ${username}
    [Documentation]  Відкриває переглядач на потрібній сторінці, готує api wrapper, тощо для користувача username.
    Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${browserAlias}
    Run Keyword If  '${username}' != 'SmartTender_Viewer'  Run Keywords
    ...  Click Element  ${open login button}
    ...  AND  Input Text  ${login field}  ${USERS.users['${username}'].login}
    ...  AND  Input Text  ${password field}  ${USERS.users['${username}'].password}
    ...  AND  Click Element  ${remember me}
    ...  AND  Click Element  ${login button}
    ...  AND  Run Keyword If  '${username}' != 'SmartTender_Owner'  Wait Until Page Contains  ${USERS.users['${username}'].login}  ${wait}
    ...  ELSE  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}

Оновити сторінку з тендером
    [Arguments]  ${username}  ${TENDER_UAID}
    Open Browser  ${synchronization}  chrome
    Wait Until Page Contains  True  ${wait}
    Close Browser
    Switch Browser  ${browserAlias}
    Reload Page

Підготуватися до редагування
    [Arguments]  ${USER}  ${TENDER_ID}
    #${status}=  Run Keyword And Return Status  Location Should Contain  webclient
    #Pass Execution If  '${status}' == '${True}'
    Go To  ${USERS.users['${USER}'].homepage}
    Click Element  LoginAnchor
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Run Keyword And Ignore Error  Click Element  id=IMMessageBoxBtnNo_CD
    Wait Until Page Contains element  ${orenda}
    Click Element  ${orenda}
    Wait Until Page Contains  Тестові аукціони на продаж
    Click Input Enter Wait  css=div[data-placeid='TENDER'] td:nth-child(4) input:nth-child(1)  ${TENDER_ID}

Пошук тендера по ідентифікатору
    [Arguments]  ${username}  ${TENDER_UAID}
    ${status}=  Run Keyword And Return Status  Location Should Contain  auktsiony-na-prodazh-aktyviv-derzhpidpryemstv
    Pass Execution If  '${status}' == '${True}'  Current page is satisfactory
    Go To  ${path to find tender}
    Wait Until page Contains Element  ${find tender field }  ${wait}
    Input Text  ${find tender field }  ${TENDER_UAID}
    Press Key  ${find tender field }  \\13
    Location Should Contain  f=${TENDER_UAID}
    ${href}=  Get Element Attribute  ${tender found}@href
    Go To  ${href}
    Select Frame  ${iframe}

Отримати текст із поля і показати на сторінці
    [Arguments]    ${fieldname}
    wait until page contains element  ${wait}
    ${return_value}=  Get Text  ${locator.${fieldname}}${locator.${fieldname}}
    [Return]  ${return_value}

Заповнити випадаючий список
    [Arguments]    ${selector}    ${content}
    Set Focus To Element  ${selector}
    Execute JavaScript  (function(){$("${selector}").val('');})()
    Input Text  ${selector}  ${content}
    Press Key  ${selector}  \\13

Click Input Enter Wait
    [Arguments]  ${locator}  ${text}
    Wait Until Page Contains Element  ${locator}
    Sleep  .2  # don't touch
    Click Element At Coordinates  ${locator}  10  5
    Input Text  ${locator}  ${text}
    Press Key  ${locator}  \\13
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Sleep  .3  # don't touch


####################################
#          OPEN PROCEDURE          #
####################################

Підготувати дані для оголошення тендера
    [Arguments]  ${username}  ${tender_data}  ${role_name}
    ${tender_data}=  Run Keyword IF  '${username}' != 'SmartTender_Viewer'  adapt_data  ${tender_data}
    ...  ELSE  Set Variable  ${tender_data}
    [Return]  ${tender_data}

Створити тендер
    [Arguments]  ${username}  ${tender_data}  #@{ARGUMENTS}
    Log  ${tender_data}
    ${items}=                     Get From Dictionary    ${tender_data.data}    items
    ${procuringEntityName}=       Get From Dictionary    ${tender_data.data.procuringEntity.identifier}    legalName
    ${title}=                     Get From Dictionary    ${tender_data.data}    title
    ${description}=               Get From Dictionary    ${tender_data.data}    description
    ${budget}=                    Get From Dictionary    ${tender_data.data.value}    amount
    ${budget}=                    Convert To String      ${budget}
    ${step_rate}=                 Get From Dictionary    ${tender_data.data.minimalStep}    amount
    ${step_rate}=                 Convert To String      ${step_rate}
    # Для фіксування ${step_rate} при зміні початковой вартості
    set global variable           ${step_rate}
    ${valTax}=                    Get From Dictionary    ${tender_data.data.value}      valueAddedTaxIncluded
    ${guarantee_amount}=          Get From Dictionary    ${tender_data.data.guarantee}    amount
    ${guarantee_amount}=          Convert To String      ${guarantee_amount}
    ${dgfID}=                     Get From Dictionary    ${tender_data.data}        dgfID
    ${minNumberOfQualifiedBids}=  Get From Dictionary    ${tender_data.data}  minNumberOfQualifiedBids
    ${auction_start}=             Get From Dictionary    ${tender_data.data.auctionPeriod}    startDate
    ${auction_start}=             smarttender_service.convert_datetime_to_smarttender_format    ${auction_start}
    ${tenderAttempts}=            Get From Dictionary    ${tender_data.data}    tenderAttempts
    Run Keyword And Ignore Error  Wait Until Page Contains element  id=IMMessageBoxBtnNo_CD
    Run Keyword And Ignore Error  Click Element  id=IMMessageBoxBtnNo_CD
    Wait Until Page Contains element  ${orenda}  ${wait}
    Click Element  ${orenda}
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Wait Until Page Contains element  ${create tender}
    Click Element  ${create tender}
    Wait Until Element Contains  cpModalMode  Оголошення  ${wait}
    # Процедура
    Run Keyword If  '${mode}' != 'dgfOtherAssets'  Run Keywords
    ...  Run Keyword And Ignore Error
    ...     Click Element  css=[data-name='OWNERSHIPTYPE']
    ...  AND  Run Keyword And Ignore Error
    ...     Click Element  css=[data-name='KDM2']
    ...  AND  Run Keyword And Ignore Error
    ...     Click Element  css=div#CustomDropDownContainer div.dxpcDropDown_DevEx table:nth-child(3) tr:nth-child(2) td:nth-child(1)
    # День старту електроного аукціону
    Click Input Enter Wait  css=#cpModalMode table[data-name='DTAUCTION'] input  ${auction_start}
    _Заповнити поле з ціною власником  ${budget}
    # з ПДВ
    Run Keyword If  ${valTax}  Click Element  css=table[data-name='WITHVAT'] span:nth-child(1)
    _Заповнити поле з мінімальним кроком аукіону  ${step_rate}
    # Загальна назва аукціону
    Click Input Enter Wait  css=#cpModalMode table[data-name='TITLE'] input  ${title}
    # Номер лоту в Замовника
    Click Input Enter Wait  css=#cpModalMode table[data-name='DGFID'] input:nth-child(1)  ${dgfID}
    #Детальний опис
    Click Input Enter Wait  css=#cpModalMode table[data-name='DESCRIPT'] textarea  ${description}
    # Організація
    Input Text  css=#cpModalMode div[data-name='ORG_GPO_2'] input  ${procuringEntityName}
    Press Key  css=#cpModalMode div[data-name='ORG_GPO_2'] input  \\09
    sleep  1  #don't touch
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Press Key  css=#cpModalMode div[data-name='ORG_GPO_2'] input  \\13
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Sleep  1  # don't touch
    # Лот виставляється на торги
    Click Element  css=#cpModalMode table[data-name='ATTEMPT'] input[type='text']
    Sleep  1  # don't touch
    Click Element  xpath=//*[text()="Невідомо"]/../following-sibling::tr[${tenderAttempts}]
    # Мінімальна кількість учасників
    run keyword if  "${minNumberOfQualifiedBids}" == '1'  run keywords
    ...  Click Element  table[data-name='PARTCOUNT']
    ...  AND  click element  xpath=(//td[text()="1"])[last()]
    # Позиції аукціону
    ${index}=  Set Variable  ${0}
    log  ${items}
    :FOR  ${item}  in  @{items}
    \  Run Keyword If  '${index}' != '0'  Click Element  css=div:nth-child(3) a[title='Додати']
    \  smarttender.Додати предмет в тендер при створенні  ${item}
    \  ${index}=  SetVariable  ${index + 1}
    _Заповнити поле гарантійного внеску  ${guarantee_amount}
    # Додати
    Click Image  css=\#cpModalMode a[data-name="OkButton"] img
    Sleep  1  # don't touch
    Wait Until Element Is Not Visible    ${webClient loading}  ${wait}
    # Оголосити аукціон
    Click Element  css=[data-name="TBCASE____SHIFT-F12N"]
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Wait Until Page Contains Element  id=IMMessageBoxBtnYes_CD
    Sleep  1  # don't touch
    Click Element  id=IMMessageBoxBtnYes_CD
    Wait Until Element Is Not Visible  id=IMMessageBoxBtnYes_CD
    Sleep  1  # don't touch
    Wait Until Element Is Not Visible    ${webClient loading}  ${wait}
    ${return_value}  Get Text  xpath=(//div[@data-placeid='TENDER']//a[text()])[1]
    Log  ${return_value}
    Log To Console  ${return_value}
    [Return]  ${return_value}

Додати предмет в тендер при створенні
    [Arguments]  ${item}
    ${description}=                 Get From Dictionary    ${item}  description
    ${quantity}=                    Get From Dictionary    ${item}  quantity
    ${quantity}=                    Convert To String      ${quantity}
    ${cpv}=                         Get From Dictionary    ${item.classification}  id
    ${cpv/cav}=                     Get From Dictionary    ${item.classification}  scheme
    ${unit}=                        Get From Dictionary    ${item.unit}  name
    ${unit}=                        smarttender_service.convert_unit_to_smarttender_format  ${unit}
    ${postalCode}                   Get From Dictionary    ${item.deliveryAddress}  postalCode
    ${locality}=                    Get From Dictionary    ${item.deliveryAddress}  locality
    ${streetAddress}                Get From Dictionary    ${item.deliveryAddress}  streetAddress
    ${latitude}                     Get From Dictionary    ${item.deliveryLocation}  latitude
    ${latitude}=                    Convert To String      ${latitude}
    ${longitude}                    Get From Dictionary    ${item.deliveryLocation}  longitude
    ${longitude}=                   Convert To String      ${longitude}
    ${contractPeriodendDate}        Get From Dictionary    ${item.contractPeriod}  endDate
    ${contractPeriodendDate}        smarttender_service.convert_datetime_to_smarttender_form  ${contractPeriodendDate}
    ${contractPeriodstartDate}      Get From Dictionary  ${item.contractPeriod}  startDate
    ${contractPeriodstartDate}      smarttender_service.convert_datetime_to_smarttender_form  ${contractPeriodstartDate}
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    sleep  1  #don't touch
    # Найменування позиції
    Click Input Enter Wait  css=#cpModalMode div[data-name='KMAT'] input[type=text]:nth-child(1)  ${description}
    # Кількість активів
    Click Input Enter Wait  css=#cpModalMode table[data-name='QUANTITY'] input  ${quantity}
    # Од. вим.
    Click Input Enter Wait  css=#cpModalMode div[data-name='EDI'] input[type=text]:nth-child(1)  ${unit}
    # Дата договору з
    Click Input Enter Wait  css=[data-name="CONTRFROM"] input  ${contractPeriodendDate}
    # по
    Click Input Enter Wait  css=[data-name="CONTRTO"] input  ${contractPeriodendDate}
    # Класифікація
    Click Element  css=[data-name="MAINSCHEME"]
    Run Keyword If  "${cpv/cav}" == "CAV" or "${cpv/cav}" == "CAV-PS"  Click Element  xpath=//td[text()="CAV"]
    ...  ELSE IF  "${cpv/cav}" == "CPV"  Click Element  xpath=//td[text()="CPV"]
    Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
    Click Input Enter Wait  css=#cpModalMode div[data-name='MAINCLASSIFICATION'] input[type=text]:nth-child(1)  ${cpv}
    # Розташування об'єкту
    sleep  1  #don't touch
    Click Input Enter Wait  css=#cpModalMode table[data-name='POSTALCODE'] input  ${postalCode}
    Click Input Enter Wait  css=#cpModalMode table[data-name='STREETADDR'] input  ${streetAddress}
    Click Input Enter Wait  css=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:nth-child(1)  ${locality}
    Click Input Enter Wait  css=#cpModalMode table[data-name='LATITUDE'] input  ${latitude}
    Click Input Enter Wait  css=#cpModalMode table[data-name='LONGITUDE'] input  ${longitude}

_Заповнити поле з ціною власником
    [Arguments]  ${value}
    Click Input Enter Wait  css=#cpModalMode table[data-name='INITAMOUNT'] input  ${value}

_Заповнити поле з мінімальним кроком аукіону
    [Arguments]  ${value}
    Click Input Enter Wait  css=#cpModalMode table[data-name='MINSTEP'] input  ${value}

_Заповнити поле гарантійного внеску
    [Arguments]  ${value}
    Click Element  xpath=(//*[@id="cpModalMode"]//span[text()='Гарантійний внесок'])[1]
    Wait Until Element Is Visible    css=[data-name='GUARANTEE_AMOUNT']
    Click Input Enter Wait  css=#cpModalMode table[data-name='GUARANTEE_AMOUNT'] input  ${value}

Завантажити документ власником
    [Arguments]  ${username}  ${filepath}  ${tender_uaid}
    smarttender.Підготуватися до редагування  ${username}  ${tender_uaid}
    Click Element  ${owner change}
    Wait Until Page Contains  Завантаження документації  ${wait}
    Click Element  ${add files tab}
    Wait Until Page Contains Element  ${add file button}
    Click Element  ${add file button}
    Choose File  ${choice file path}  ${filepath}
    Click Element  ${ok add file}

Завантажити документ
    [Arguments]  ${username}  ${filepath}  ${tender_uaid}
    [Documentation]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  path to file
    ...  ${ARGUMENTS[2]}  tenderID
    Завантажити документ власником  ${username}  ${filepath}  ${tender_uaid}
    [Teardown]  _Закрити вікно редагування

Завантажити ілюстрацію
    [Arguments]    ${username}  ${tender_uaid}  ${filepath}
    [Documentation]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  tenderID
    ...  ${ARGUMENTS[2]}  path to file
    Pass Execution If  '${role}' == 'provider' or '${role}' == 'viewer'  Даний учасник не може завантажити ілюстрацію
    log to console  Завантажити ілюстрацію
    Завантажити документ власником  ${username}  ${filepath}  ${tender_uaid}
    Click Element  xpath=(//*[text()="Інший тип"])[last()-1]
    Click Element  xpath=(//*[text()="Інший тип"])[last()-1]
    Click Element  xpath=(//*[text()="Ілюстрація"])[2]
    [Teardown]  _Закрити вікно редагування

Завантажити документ в тендер з типом
    [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${doc_type}
    Pass Execution If  '${role}' == 'provider' or '${role}' == 'viewer'  Даний учасник не може завантажити документ в тендер
    Завантажити документ власником  ${username}  ${filepath}  ${tender_uaid}
    log to console  Завантажити документ в тендер з типом
    debug
    ${documentTypeNormalized}=    map_to_smarttender_document_type    ${doc_type}
    click element  xpath=(//*[text()="Інший тип"])[last()-1]
    click element  xpath=(//*[text()="Інший тип"])[last()-1]
    click element  xpath=(//*[text()="${documentTypeNormalized}"])[2]
    [Teardown]  _Закрити вікно редагування

Додати документ
    [Arguments]  ${document}
    Log  ${document[0]}
    Click Element  ${add files tab}
    Wait Until Page Contains Element  ${add file button}
    Click Element  ${add file button}
    Choose File  jquery=#cpModalMode input[type=file]:eq(1)    ${document[0]}
    Click Image  jquery=#cpModalMode div.dxrControl_DevEx a:contains('ОК') img

Додати предмет закупівлі
    [Arguments]    ${user}    ${tenderId}    ${item}
    ${description}=    Get From Dictionary    ${item}     description
    ${quantity}=       Get From Dictionary    ${item}     quantity
    ${cpv}=            Get From Dictionary    ${item.classification}     id
    ${unit}=           Get From Dictionary    ${item.unit}     name
    ${unit}=           smarttender_service.convert_unit_to_smarttender_format    ${unit}
    smarttender.Підготуватися до редагування     ${user}    ${tenderId}
    click element  ${owner change}
    Wait Until Element Contains  jquery=#cpModalMode     Коригування    ${wait}
    Page Should Not Contain Element  jquery=#cpModalMode div.gridViewAndStatusContainer a[title='Додати']
    [Teardown]  _Закрити вікно редагування

Видалити предмет закупівлі
    [Arguments]  ${user}  ${tenderId}  ${itemId}
    ${readyToEdit} =  Execute JavaScript  return(function(){return ((window.location.href).indexOf('webclient') !== -1).toString();})()
    Run Keyword If  '${readyToEdit}' != 'true'  Підготуватися до редагування  ${user}  ${tenderId}
    click element  ${owner change}
    Wait Until Element Contains  id=cpModalMode  Коригування  ${wait}
    Page Should Not Contain Element  jquery=#cpModalMode a[title='Удалить']
    [Teardown]      _Закрити вікно редагування

Внести зміни в тендер
    [Arguments]  ${user}  ${tenderId}  ${field}  ${value}
    Log  ${field}
    Log  ${value}
    Pass Execution If  '${role}'=='provider' or '${role}'=='viewer'  Данний користувач не може вносити зміни в аукціон
    smarttender.Підготуватися до редагування  ${user}  ${tenderId}
    Click Element  ${owner change}
    Wait Until Element Contains  id=cpModalMode  Коригування  ${wait}
    ${value}=  convert to string  ${value}
    run keyword if
    ...  '${field}' == 'guarantee.amount'
    ...     _Заповнити поле гарантійного внеску  ${value}
    ...  ELSE IF  '${field}' == 'value.amount'  run keywords
    ...     _Заповнити поле з ціною власником  ${value}
    ...     AND  _Заповнити поле з мінімальним кроком аукіону  ${step_rate}
    ...  ELSE IF  '${field}' == 'minimalStep.amount'
    ...     _Заповнити поле з мінімальним кроком аукіону  ${value}
    ...  ELSE  Fail
    [Teardown]  _Закрити вікно редагування

_Закрити вікно редагування
    Click Element  css=div.dxpnlControl_DevEx a[title='Зберегти'] img
    Run Keyword And Ignore Error  _Закрити вікно з помилкою

_Закрити вікно з помилкою
    Click Element  css=#IMMessageBoxBtnOK:nth-child(1)
    Click Element  xpath=//*[@id="cpModalMode"]//*[text()='Записати']
    Click Element  id=IMMessageBoxBtnOK_CD

Змінити опис тендера
    [Arguments]       ${description}
    Set Focus To Element  jquery=table[data-name='DESCRIPT'] textarea
    Input Text  jquery=table[data-name='DESCRIPT'] textarea      ${description}

Отримати інформацію із тендера
    [Arguments]  ${username}  ${tender_uaid}  ${fieldname}
    smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
    log  ${fieldname}
    log to console  Отримати інформацію із тендера
    Run Keyword if  '${fieldname}' == 'questions[0].title'  debug
    ${location}=  Run Keyword And Return Status  Location Should Contain  auktsiony-na-prodazh-aktyviv-derzhpidpryemstv
    ${type}=  string_contains  ${fieldname}
    Run Keyword If  '${type}' == 'questions' and '${location}' == 'True'  smarttender.Відкрити сторінку із даними запитань
    ...  Else IF  '${type}' == 'questions' and '${location}' == 'False'  Select Frame  ${iframe}
    Run Keyword If  '${type}' == 'cancellation' and '${location}' == 'True'  smarttender.Відкрити сторінку із данними скасування
    ${selector}=  auction_field_info  ${fieldname}
    ${ret}=  Get Text  ${selector}
    ${ret}=  convert_result  ${fieldname}  ${ret}
    [Return]  ${ret}

Отримати інформацію із предмету
    [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${fieldname}
    Fail  Temporary using keyword 'Отримати інформацію із тендера' until will be updated keyword 'Отримати інформацію із предмету'

Отримати кількість предметів в тендері
    [Arguments]  ${user}  ${tenderId}
    smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
    ${numberOfItems}=  Get Element Count  xpath=//div[@id='home']//div[@class='well']
    [Return]  ${numberOfItems}

Отримати інформацію із запитання
    [Documentation]  does it work somewhere?
    [Arguments]  ${user}  ${tenderId}  ${objectId}  ${field}
    Fail  it should not work
    ${selector}=  question_field_info  ${field}  ${objectId}
    Run Keyword And Ignore Error  smarttender.Відкрити сторінку із даними запитань
    ${ret}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
    [Return]    ${ret}

Відкрити аналіз тендера
    ${title}=  Get Title
    Return From KeyWord If  '${title}' != 'Комерційні торги та публічні закупівлі в системі ProZorro'
    smarttender.Пошук тендера по ідентифікатору  0  ${TENDER['TENDER_UAID']}
    ${href}=  Get Element Attribute  jquery=a.button.analysis-button@href
    go to  ${href}
    Select Frame  ${iframe}

Відкрити скарги тендера
    [Arguments]  ${username}
    smarttender.Пошук тендера по ідентифікатору  ${username}  ${TENDER['TENDER_UAID']}
    ${href}=  Get Element Attribute  jquery=a.compliant-button@href
    go to  ${href}
    Select Frame  ${iframe}

Отримати інформацію із документа
    [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
    log  ${field}
    log  ${doc_id}
    Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
    ${isCancellation}=  Set Variable If  '${TEST NAME}' == 'Відображення опису документа до скасування лоту' or '${TEST NAME}' == 'Відображення заголовку документа до скасування лоту' or '${TEST NAME}' == 'Відображення вмісту документа до скасування лоту'   True    False
    Run Keyword If  ${isCancellation} == True  smarttender.Відкрити сторінку із данними скасування
    ${selector}=  run keyword if  '${TEST NAME}' == 'Відображення заголовку документа до скасування лоту'
    ...    document_fields_info  title1  ${doc_id}  ${isCancellation}
    ...  ELSE
    ...    document_fields_info  ${field}  ${doc_id}  ${isCancellation}
    ${result}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
    [Return]  ${result}

Перейти до запитань
    [Arguments]  @{ARGUMENTS}
    [Documentation]  ${ARGUMENTS[0]} = username
    ...  ${ARGUMENTS[1]} = ${TENDER_UAID}
    smarttender.Оновити сторінку з тендером  @{ARGUMENTS}

Отримати інформацію із документа по індексу
    [Arguments]  ${user}  ${tenderId}  ${doc_index}  ${field}
    ${result}=  Execute JavaScript  return(function(){ return $("div.row.document:eq(${doc_index+1}) span.info_attachment_type:eq(0)").text();})()
    ${resultDoctype}=  map_from_smarttender_document_type  ${result}
    [Return]  ${resultDoctype}

Задати запитання на тендер
    [Arguments]  ${USERNAME}  ${TENDER_UAID}  ${QUESTION_DATE}
    ${title}=  Get From Dictionary  ${QUESTION_DATE.data}  title
    ${description}=  Get From Dictionary  ${QUESTION_DATE.data}  description
    smarttender.Відкрити сторінку із даними запитань
    smarttender._Створити запитання  ${title}  ${description}
    # TODO  Don't know how to get value from the hidden element with Selenium2Library
    ${question_id}=  Execute JavaScript  return (function() {return $("span.question_idcdb").text() })()
    # TODO  Don't know how it work
    ${question_data}=  smarttender_service.get_question_data  ${question_id}
    [Return]  ${question_data}

_Створити запитання
    [Arguments]  ${title}  ${description}
    Click Element  css=#questions span[role="presentation"]
    Click Element  css=.select2-results li:nth-child(2)
    Click element  id=add-question
    Select Frame  ${iframe}
    Input Text  id=subject  ${title}
    Input Text  id=question  ${description}
    Click Element  css=button[type='button']
    Log To Console  do some thing
    debug
    ${status}=  get text  xpath=//*[@class='ivu-alert-message']/span
    Log  ${status}
    Wait Until Element Is Not Visible  ${loading}  ${wait}
    Should Be Equal  ${status}  Ваше запитання успішно надіслане
    Should Not Be Equal  ${status}  Період обговорення закінчено
    Reload Page
    Select Frame  ${iframe}

Задати запитання на предмет
    [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
    ${title}=  Get From Dictionary  ${question.data}  title
    ${description}=  Get From Dictionary  ${question.data}  description
    smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
    Run Keyword And Ignore Error  smarttender.Відкрити сторінку із даними запитань
    Click Element  jquery=#select2-question-relation-container:eq(0)
    Set Focus To Element  jquery=.select2-search__field:eq(0)
    Input Text  jquery=.select2-search__field:eq(0)  ${item_id}
    Press Key  jquery=.select2-search__field:eq(0)  \\13
    Click Element  jquery=input#add-question
    Select Frame  ${iframe}
    input text  id=subject  ${title}
    input text  id=question  ${description}
    click element  xpath=//button
    ${status}=  get text  xpath=//*[@class='ivu-alert-message']/span
    Log  ${status}
    Should Not Be Equal  ${status}  Період обговорення закінчено
    reload page
    select frame  ${iframe}
    ${question_id}=  Execute JavaScript  return (function() {return $("span.question_idcdb").text() })()
    ${question_data}=  smarttender_service.get_question_data  ${question_id}
    [Return]  ${question_data}

Відповісти на запитання
    [Arguments]  ${user}  ${tenderId}  ${answer}  ${questionId}
    smarttender.Підготуватися до редагування  ${user}  ${tenderId}
    ${answerText}=      Get From Dictionary     ${answer.data}    answer
    Click Element    jquery=#MainSted2PageControl_TENDER ul.dxtc-stripContainer li.dxtc-tab:eq(1)
    Wait Until Page Contains    ${questionId}
    Set Focus To Element    jquery=div[data-placeid='TENDER'] table.hdr:eq(3) tbody tr:eq(1) td:eq(2) input:eq(0)
    Input Text      jquery=div[data-placeid='TENDER'] table.hdr:eq(3) tbody tr:eq(1) td:eq(2) input:eq(0)    ${questionId}
    Press Key       jquery=div[data-placeid='TENDER'] table.hdr:eq(3) tbody tr:eq(1) td:eq(2) input:eq(0)        \\13
    Wait Until Element Is Not Visible    ${webClient loading}  ${wait}
    Click Image    jquery=.dxrControl_DevEx a[title*='Змінити'] img:eq(0)
    Set Focus To Element       jquery=#cpModalMode textarea:eq(0)
    Input Text    jquery=#cpModalMode textarea:eq(0)     ${answerText}
    Click Element    jquery=#cpModalMode span.dxICheckBox_DevEx:eq(0)
    Click Image    jquery=#cpModalMode .dxrControl_DevEx .dxr-buttonItem:eq(0) img
    Click Element     jquery=#cpIMMessageBox .dxbButton_DevEx:eq(0)
    Wait Until Page Contains    Відповідь надіслана на сервер ЦБД        ${wait}

Подати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} == ${test_bid_data}
    smarttender.Пройти кваліфікацію для подачі пропозиції  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}  ${ARGUMENTS[2]}
    Log  ${mode}
    ${response}=  Run Keyword If  '${mode}' == 'dgfInsider'
    ...    smarttender.Прийняти участь в тендері dgfInsider  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}  ${ARGUMENTS[2]}
    ...  ELSE
    ...    smarttender.Прийняти участь в тендері  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}  ${ARGUMENTS[2]}
    [Return]  ${response}

Пройти кваліфікацію для подачі пропозиції
    [Arguments]  ${user}  ${tenderId}  ${bid}
    ${temp}=  Get Variable Value  ${bid['data'].qualified}
    ${shouldQualify}=  convert_bool_to_text  ${temp}
    Return From Keyword If  '${shouldQualify}' == 'false'
    Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
    Wait Until Page Contains Element  jquery=a#participate  10
    ${lotId}=  Execute JavaScript  return(function(){return $("span.info_lotId").text()})()
    Click Element  jquery=a#participate
    Wait Until Page Contains Element  jquery=iframe#widgetIframe:eq(1)  ${wait}
    Select Frame  jquery=iframe#widgetIframe:eq(1)
    Wait Until Page Contains Element  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][1]//input  ${wait}
    input text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][1]//input  Іван
    input text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][2]//input  Іванов
    input text  xpath=.//*[@class="ivu-form-item"][2]//input  Іванович
    input text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][3]//input  +38011111111
    ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
    Run Keyword And Ignore Error  smarttender.Додати документ до кваліфікації  jquery=input#GUARAN  ${file_path}
    Run Keyword And Ignore Error  smarttender.Додати документ до кваліфікації  jquery=input#FIN  ${file_path}
    Run Keyword And Ignore Error  smarttender.Додати документ до кваліфікації  jquery=input#NOTDEP  ${file_path}
    Run Keyword And Ignore Error  smarttender.Додати документ до кваліфікації  xpath=//input[@type="file"]  ${file_path}
    click element  xpath=//*[@class="group-line"]//input
    click element  xpath=//button[@class="ivu-btn ivu-btn-primary pull-right ivu-btn-large"]
    Unselect Frame
    Go To  http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_QA.ACCEPTAUCTIONBIDREQUEST&args={"IDLOT":"${lotId}","SUCCESS":"true"}&ticket=
    Wait Until Page Contains  True

Додати документ до кваліфікації
    [Arguments]  ${selector}  ${doc}
    Choose File  ${selector}  ${doc}

Заповнити поле значенням
    [Arguments]  ${selector}  ${value}
    Set Focus To Element  ${selector}
    Input Text  ${selector}  ${value}

Змінити цінову пропозицію
    [Arguments]  @{ARGUMENTS}
    [Documentation]  ?
    ${value}=  convert_bool_to_text  ${ARGUMENTS[3]}
    ${href}=  Get Element Attribute  jquery=a#bid@href
    go to  ${href}
    Set Focus To Element  jquery=div#lotAmount0 input
    Input Text  jquery=div#lotAmount0 input  ${value}
    Click Element  jquery=button#submitBidPlease
    Run Keyword And Ignore Error  Wait Until Page Contains  Пропозицію прийнято  ${wait}
    ${response}=  smarttender_service.get_bid_response    ${value}
    reload page
    [Return]  ${response}

Прийняти участь в тендері
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    ...    ${ARGUMENTS[2]} ==  ${test_bid_data}
    ${amount}=  Get From Dictionary  ${ARGUMENTS[2].data.value}  amount
    ${amount}=  convert to string  ${amount}
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    Wait Until Page Contains Element  jquery=a#bid  ${wait}
    ${href}=  Get Element Attribute  jquery=a#bid@href
    go to  ${href}
    Wait Until Page Contains  Пропозиція по аукціону
    Set Focus To Element  jquery=div#lotAmount0 input
    Input Text  jquery=div#lotAmount0 input  ${amount}
    Click Element  jquery=button#submitBidPlease
    Wait Until Page Contains  Пропозицію прийнято  ${wait}
    ${response}=  smarttender_service.get_bid_response  ${${amount}}
    [Return]  ${response}

Прийняти участь в тендері dgfInsider
    [Arguments]  @{ARGUMENTS}
    [Documentation]  ${ARGUMENTS[0]} == username
    ...  ${ARGUMENTS[1]} == TENDER_UAID
    ...  ${ARGUMENTS[2]} == bid_info
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    Wait Until Page Contains Element  jquery=a#bid  ${wait}
    ${href}=  Get Element Attribute  jquery=a#bid@href
    go to  ${href}
    Wait Until Page Contains  Пропозиція по аукціону  ${wait}
    Wait Until Page Contains Element  jquery=button#submitBidPlease  ${wait}
    Click Element  jquery=button#submitBidPlease
    Wait Until Page Contains Element  jquery=button:contains('Так')  ${wait}
    Click Element  jquery=button:contains('Так')
    Wait Until Page Contains  Пропозицію прийнято  ${wait}
    [Return]  ${ARGUMENTS[2]}

Отримати інформацію із пропозиції
    [Arguments]  @{ARGUMENTS}
    [Documentation]  ${ARGUMENTS[0]} == username
    ...  ${ARGUMENTS[1]} == TENDER_UAID
    ...  ${ARGUMENTS[2]} == field
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    ${ret}=  smarttender.Отримати інформацію із тендера  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}  ${ARGUMENTS[2]}
    ${ret}=  Execute JavaScript  return (function() { return parseFloat('${ret}') })()
    [Return]  ${ret}

Завантажити документ в ставку
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == path
    ...    ${ARGUMENTS[2]} == tenderid
    Pass Execution If  '${mode}' == 'dgfOtherAssets'  Для типа 'Продаж майна банків, що ліквідуються' документы не вкладываются
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[2]}
    Wait Until Page Contains Element  jquery=a#bid  ${wait}
    ${href}=  Get Element Attribute  jquery=a#bid@href
    go to  ${href}
    Wait Until Page Contains  Пропозиція  10
    Wait Until Page Contains Element  jquery=button:contains('Обрати файли')  ${wait}
    Choose File  jquery=button:contains('Обрати файли')  ${ARGUMENTS[1]}
    Click Element  jquery=button#submitBidPlease
    Wait Until Page Contains Element  jquery=button:contains('Так')  ${wait}
    Click Element  jquery=button:contains('Так')
    Wait Until Page Contains  Пропозицію прийнято  ${wait}

Змінити документ в ставці
    [Arguments]  @{ARGUMENTS}
    [Documentation]  ?
    smarttender.Завантажити документ в ставку  ${ARGUMENTS[0]}  ${ARGUMENTS[2]}  ${TENDER['TENDER_UAID']}

Відкрити сторінку із даними запитань
    ${href}=  Get Element Attribute  ${question_button}@href
    Go to  ${href}
    Select Frame  ${iframe}

Отримати документ
    [Arguments]  ${user}  ${tenderId}  ${docId}
    Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
    ${selector}=  document_fields_info  content  ${docId}  False
    ${fileUrl}=  Get Element Attribute  jquery=div.row.document:contains('${docId}') a.info_attachment_link:eq(0)@href
    ${result}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
    smarttender_service.download_file  ${fileUrl}  ${OUTPUT_DIR}${/}${result}
    [Return]  ${result}

Додати Virtual Data Room
    [Arguments]    ${user}    ${tenderId}     ${link}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити ілюстрацію
    Підготуватися до редагування    ${user}     ${tenderId}
    click element  ${owner change}
    Wait Until Page Contains    Завантаження документації
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    Set Focus To Element    jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)
    Input Text    jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)    ${link}
    Press Key    jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)    \\13
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img

Додати публічний паспорт активу
    [Arguments]    ${user}    ${tenderId}     ${link}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може завантажити паспорт активу
    Підготуватися до редагування    ${user}     ${tenderId}
    click element  ${owner change}
    Wait Until Page Contains    Завантаження документації
    Click Element     jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
    Set Focus To Element    jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)
    Input Text    jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)    ${link}
    Press Key    jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)    \\13
    Click Image     jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img

Додати офлайн документ
    [Arguments]    ${user}    ${tenderId}     ${description}
    Pass Execution If  '${role}' == 'provider' or '${role}' == 'viewer'  Даний учасник не може додати офлайн документ
    Підготуватися до редагування    ${user}     ${tenderId}
    click element  ${owner change}
    Wait Until Page Contains    Завантаження документації  ${wait}
    log to console  Додати офлайн документ
    debug
    Click Element  ${add files tab}
    input text  xpath=(//*[@data-type="EditBox"])[last()]//textarea  ${description}
    [Teardown]  _Закрити вікно редагування

Завантажити фінансову ліцензію
    [Arguments]    ${user}    ${tenderId}    ${license_path}
    smarttender.Завантажити документ в ставку    ${user}    ${license_path}    ${tenderId}

Отримати кількість документів в тендері
    [Arguments]  ${user}  ${tenderId}
    Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
    ${documentNumber}=  Execute JavaScript  return (function(){return $("div.row.document").length-1;})()
    ${documentNumber}=  Convert To Integer  ${documentNumber}
    [Return]  ${documentNumber}

####################################
#          CANCELLATION            #
####################################

Скасувати закупівлю
    [Arguments]    ${user}     ${tenderId}     ${reason}    ${file}    ${descript}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може скасувати тендер
    ${documents}=    create_fake_doc
    Підготуватися до редагування    ${user}     ${tenderId}
    Click Element       jquery=a[data-name='F2_________GPCANCEL']
    Wait Until Page Contains    Протоколи скасування
    Set Focus To Element    jquery=#cpModalMode table[data-name='reason'] input:eq(1)
    Execute JavaScript    (function(){$("#cpModalMode table[data-name='reason'] input:eq(1)").val('');})()
    Input Text    jquery=#cpModalMode table[data-name='reason'] input:eq(1)    ${reason}
    Press Key        jquery=#cpModalMode table[data-name='reason'] input:eq(1)         \\13
    click element  xpath=//div[@title="Додати"]
    Choose File  id=fileUpload  ${file}
    Click Element    xpath=//*[@class="dxr-group mygroup"][1]
    click element  xpath=.//*[@data-type="TreeView"]//tbody/tr[2]
    click element  xpath=.//*[@data-type="TreeView"]//tbody/tr[2]
    Set Focus To Element    jquery=table[data-name='DocumentDescription'] input:eq(0)
    Input Text    jquery=table[data-name='DocumentDescription'] input:eq(0)    ${descript}
    Press Key  jquery=table[data-name='DocumentDescription'] input:eq(0)  \\13
    Click Element  jquery=a[title='OK']
    Wait Until Page Contains    аукціон буде
    Click Element    jquery=#IMMessageBoxBtnYes

Скасувати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == ${TENDER_UAID}
    smarttender.Пошук тендера по ідентифікатору     ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    ${href} =     Get Element Attribute      jquery=a:Contains('Подати пропозицію')@href
    go to  ${href}
    wait until page contains element  ${cancellation offers button}
    Run Keyword And Ignore Error  click element  ${cancellation offers button}
    Run Keyword And Ignore Error  click element  ${cancel. offers confirm button}
    ${passed}=  run keyword and return status  wait until page contains element  ${ok button}  ${wait}
    Run keyword if  '${passed}'=='${False}'  Cancellation offer continue
    Run Keyword And Ignore Error  click element   ${ok button}
    ${passed}=  run keyword and return status  wait until page does not contain element   ${ok button}
    Run keyword if  '${passed}'=='${False}'  Cancellation offer continue

Відкрити сторінку із данними скасування
    log to console  Відкрити сторінку із данними скасування(правимо селектори)
    debug
    Click Element  jquery=a#cancellation:eq(0)  #css=a#cancellation
    Select Frame  jquery=#widgetIframe
    [Return]

Закрити сторінку із данними скасування
    Click button  jquery=button.close:eq(0)
    Select Frame  ${iframe}
    [Return]

####################################
#             AUCTION              #
####################################

Отримати посилання на аукціон для глядача
    [Arguments]  @{ARGUMENTS}
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    ${href}=  Get Element Attribute  css=a#view-auction@href
    Log  ${href}
    [Return]  ${href}

Отримати посилання на аукціон для учасника
    [Arguments]  @{ARGUMENTS}
    smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
    Wait Until Page Contains Element  css=a#to-auction
    Click Element  css=a#to-auction
    Wait Until Page Contains Element  css=iframe#widgetIframe  ${wait}
    Select Frame  css=iframe#widgetIframe
    Wait Until Page Contains Element  jquery=a.link-button:eq(0)  ${wait}
    ${return_value}=  Get Element Attribute  jquery=a.link-button:eq(0)@href
    [Return]  ${return_value}

####################################
#          QUALIFICATION           #
####################################

Підтвердити наявність протоколу аукціону
	[Arguments]  ${user}  ${tenderId}  ${bidIndex}
    Run Keyword  smarttender.Підготуватися до редагування  ${user}  ${tenderId}
    Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
    ${normalizedIndex}=  normalize_index  ${bidIndex}  1
    Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains Element  xpath=//*[@data-name="OkButton"]  ${wait}
    Click Element  xpath=//*[@data-name="OkButton"]

Отримати кількість документів в ставці
    [Arguments]  ${user}  ${tenderId}  ${bidIndex}
    Run Keyword  smarttender.Підготуватися до редагування  ${user}  ${tenderId}
    Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
    ${normalizedIndex}=  normalize_index  ${bidIndex}  1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції  ${wait}
    ${count}=     Execute JavaScript    return(function(){ var counter = 0;var documentSelector = $("#cpModalMode tr label:contains('Кваліфікація')").closest("tr");while (true) { documentSelector = documentSelector.next(); if(documentSelector.length == 0 || documentSelector[0].innerHTML.indexOf("label") === -1){ break;} counter = counter +1;} return counter;})()
    [Return]    ${count}

Підтвердити постачальника
    [Arguments]    @{ARGUMENTS}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підтвердити постачальника
    Підготуватися до редагування     ${ARGUMENTS[0]}      ${ARGUMENTS[1]}
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    ${normalizedIndex}=     normalize_index    ${ARGUMENTS[2]}     1
    Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    Click Element  jquery=a[title='Кваліфікація']
    Click Element  query=div.dxbButton_DevEx:contains('Підтвердити оплату')
    Click Element  jquery=div#IMMessageBoxBtnYes
    ${status}=     Execute JavaScript      return  (function() { return $("div[data-placeid='BIDS'] tr.rowselected td:eq(5)").text() } )()
    Should Be Equal       '${status}'      'Визначений переможцем'

Отримати дані із документу пропозиції
    [Arguments]    ${user}    ${tenderId}    ${bid_index}    ${document_index}    ${field}
    Run Keyword    smarttender.Підготуватися до редагування    ${user}    ${tenderId}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    ${normalizedIndex}=     normalize_index    ${bid_index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
    Wait Until Page Contains    Вкладення до пропозиції  ${wait}
    ${selectedType}=     Execute JavaScript    return(function(){ var startElement = $("#cpModalMode tr label:contains('Квалификации')"); var documentSelector = $(startElement).closest("tr").next(); if(${document_index} > 0){ for (i=0;i<=${document_index};i++) {documentSelector = $(documentSelector).next();}}if($(documentSelector).length == 0) {return "";} return "auctionProtocol";})()
    [Return]    ${selectedType}

Скасування рішення кваліфікаційної комісії
    [Arguments]    ${user}    ${tenderId}    ${index}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'tender_owner'   Доступно тільки для другого учасника
    Run Keyword    smarttender.Пошук тендера по ідентифікатору    ${user}    ${tenderId}
    Click Element    jquery=div#auctionResults div.row.well:eq(${index}) div.btn.withdraw:eq(0)
    Select Frame    jquery=iframe#cancelPropositionFrame
    Click Element    jquery=#firstYes
    Click Element    jquery=#secondYes

Дискваліфікувати постачальника
    [Arguments]    ${user}    ${tenderId}    ${index}    ${description}
    Підготуватися до редагування     ${user}      ${tenderId}
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    ${normalizedIndex}=     normalize_index    ${index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    click element  xpath=//a[@title="Кваліфікація"]
    Click Element    jquery=div.dxbButton_DevEx.dxbButtonSys.dxbTSys span:contains('Відхилити пропозицію')
    click element  id=IMMessageBoxBtnNo_CD
    Set Focus To Element    jquery=#cpModalMode textarea
    Input Text    jquery=#cpModalMode textarea    ${description}
    click element  xpath=//span[text()="Зберегти"]
    click element  id=IMMessageBoxBtnYes_CD

Завантажити протокол аукціону
    [Arguments]    ${user}    ${tenderId}    ${filePath}    ${index}
    Run Keyword    smarttender.Пошук тендера по ідентифікатору    ${user}    ${tenderId}
    ${href}=    Get Element Attribute    jquery=div#auctionResults div.row.well:eq(${index}) a.btn.btn-primary@href
    Go To      ${href}
    Click Element    jquery=a.attachment-button:eq(0)
    ${hrefQualification}=    Get Element Attribute    jquery=a.attachment-button:eq(0)@href
    go to  ${hrefQualification}
    Choose File    jquery=input[name='fieldUploaderTender_TextBox0_Input']:eq(0)    ${filePath}
    Click Element    jquery=div#SubmitButton__1_CD
    Page Should Contain     Кваліфікаційні документи відправлені

Завантажити протокол аукціону в авард
    [Arguments]    ${username}    ${tender_uaid}    ${filepath}    ${award_index}
    smarttender.Завантажити документ рішення кваліфікаційної комісії    ${username}    ${filepath}    ${tender_uaid}     ${award_index}
    Click Element    jquery=div.dxbButton_DevEx:eq(2)
    Click element  xpath=//span[text()="Зберегти"]
    click element  id=IMMessageBoxBtnYes_CD

Завантажити документ рішення кваліфікаційної комісії
    [Arguments]    ${user}    ${filePath}    ${tenderId}    ${index}
    Pass Execution If      '${role}' == 'provider' or '${role}' == 'viewer'     Даний учасник не може підтвердити постачальника
    Підготуватися до редагування     ${user}      ${tenderId}
    Click Element      jquery=#MainSted2TabPageHeaderLabelActive_1
    ${normalizedIndex}=  normalize_index    ${index}     1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
    Click Element      jquery=a[title='Кваліфікація']
    Click Element    xpath=//span[text()='Перегляд...']
    Choose File  ${choice file path}  ${filePath}
    Click Element    ${ok add file}

####################################
#         CONTRACT SIGNING         #
####################################

Завантажити угоду до тендера
    [Arguments]    @{ARGUMENTS}
    [Documentation]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  tenderID
    ...  ${ARGUMENTS[2]}  contract_number
    ...  ${ARGUMENTS[3]}  file path
    Run Keyword    smarttender.Підготуватися до редагування      ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    Click Element     jquery=#MainSted2TabPageHeaderLabelActive_1
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    Click Element    jquery=a[title='Прикріпити договір']:eq(0)
    Wait Until Page Contains    Вкладення договірних документів
    Set Focus To Element     jquery=td.dxic input[maxlength='30']
    Input Text    jquery=td.dxic input[maxlength='30']    11111111111111
    click element  xpath=//span[text()="Перегляд..."]
    Choose File  ${choice file path}  ${ARGUMENTS[3]}
    Click Element    ${ok add file}
    Click Element    jquery=a[title='OK']:eq(0)
    Wait Until Element Is Not Visible    ${webClient loading}  ${wait}

Підтвердити підписання контракту
    [Arguments]    @{ARGUMENTS}
    [Documentation]  ${ARGUMENTS[0]}  role
    ...  ${ARGUMENTS[1]}  tenderID
    ...  ${ARGUMENTS[2]}  contract_number
    smarttender.Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
    Click Element    jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
    Click Element    jquery=a[title='Підписати договір']:eq(0)
    Click Element    jquery=#IMMessageBoxBtnYes_CD:eq(0)
    Click Element    jquery=#IMMessageBoxBtnOK:eq(0)