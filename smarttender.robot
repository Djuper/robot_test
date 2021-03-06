﻿*** Settings ***
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
${wait}                                 120
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
${your request is sending}              css=.ivu-message-notice-content-textddd
${wraploading}                          css=#wrapLoading .load-icon-div i

#webclient
${owner change}                         css=[data-name="TBCASE____F4"]
${ok add file}                          jquery=span:Contains('ОК'):eq(0)
${webClient loading}                    id=LoadingPanel
${orenda}                               css=[data-itemkey='438']
${create tender}                        css=[data-name="TBCASE____F7"]
${add file button}                      css=#cpModalMode div[data-name='BTADDATTACHMENT']
${choice file path}                     xpath=//*[@type='file'][1]
${add files tab}                        xpath=//li[contains(@class, 'dxtc-tab')]//span[text()='Завантаження документації']
${correct tender button}                xpath=//span[contains(text(), 'Коригувати')]
${find tender_id field}                 css=div[data-placeid='TENDER'] td:nth-child(4) input:nth-child(1)
${discuss tab}                          jquery=#MainSted2PageControl_TENDER ul.dxtc-stripContainer li.dxtc-tab:eq(1)
${discuss search field}                 css=tbody .has-system-column:nth-child(2)>td:nth-child(3)>input
${answer field for question}            xpath=(//textarea)[1]
${answer question checkbox}             css=#cpModalMode span.dxICheckBox_DevEx
${save changes}                         xpath=//*[@id='cpModalMode']//span[contains(text(), 'Зберегти')]
${yes button}                           css=#IMMessageBoxBtnYes_CD
${ok button}                            css=#IMMessageBoxBtnOK_CD

*** Keywords ***
####################################
#        Операції з лотом          #
####################################
Підготувати клієнт для користувача
  [Arguments]  ${username}
  [Documentation]  Відкриває переглядач на потрібній сторінці, готує api wrapper, тощо для користувача username.
  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=${browserAlias}
  Run Keyword If  '${username}' != 'SmartTender_Viewer'  Login_  ${username}

Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  [Documentation]  Адаптує початкові дані для створення лоту. Наприклад, змінити дані про procuringEntity на дані про користувача tender_owner на майданчику.
  ...  Перевіряючи значення аргументу role_name, можна адаптувати різні дані для різних ролей
  ...  (наприклад, необхідно тільки для ролі tender_owner забрати з початкових даних поле mode: test, а для інших ролей не потрібно робити нічого).
  ...  Це ключове слово викликається в циклі для кожної ролі, яка бере участь в поточному сценарії.
  ...  З ключового слова потрібно повернути адаптовані дані tender_data. Різниця між початковими даними і кінцевими буде виведена в консоль під час запуску тесту.
  ${tender_data}=  smarttender_service.adapt_data  ${tender_data}
  [Return]  ${tender_data}

Створити тендер
  [Arguments]  ${username}  ${tender_data}
  [Documentation]  Створює лот з початковими даними tender_data.
  Log  ${tender_data}
  ${items}=                     Get From Dictionary    ${tender_data.data}  items
  ${procuringEntityName}=       Get From Dictionary    ${tender_data.data.procuringEntity.identifier}  legalName
  ${title}=                     Get From Dictionary    ${tender_data.data}  title
  ${description}=               Get From Dictionary    ${tender_data.data}  description
  ${budget}=                    Get From Dictionary    ${tender_data.data.value}  amount
  ${budget}=                    Convert To String      ${budget}
  ${step_rate}=                 Get From Dictionary    ${tender_data.data.minimalStep}  amount
  ${step_rate}=                 Convert To String      ${step_rate}
  # Для фіксування кроку аукціону при зміні початковой вартості лоту
  set global variable           ${step_rate}
  ${valTax}=                    Get From Dictionary    ${tender_data.data.value}  valueAddedTaxIncluded
  ${guarantee_amount}=          Get From Dictionary    ${tender_data.data.guarantee}  amount
  ${guarantee_amount}=          Convert To String      ${guarantee_amount}
  ${dgfID}=                     Get From Dictionary    ${tender_data.data}  dgfID
  ${minNumberOfQualifiedBids}=  Get From Dictionary    ${tender_data.data}  minNumberOfQualifiedBids
  ${auction_start}=             Get From Dictionary    ${tender_data.data.auctionPeriod}  startDate
  ${auction_start}=             smarttender_service.convert_datetime_to_smarttender_format  ${auction_start}
  ${tenderAttempts}=            Get From Dictionary    ${tender_data.data}  tenderAttempts
  Відкрити вікно для створення тендера_
  Вибрати тип процедури_
  Ввести дату старту аукціону_  ${auction_start}
  Заповнити поле з ціною власником_  ${budget}
  З ПДВ_  ${valTax}
  Заповнити поле з мінімальним кроком аукіону_  ${step_rate}
  Ввести загальну назву аукціону_  ${title}
  Ввести номер лоту в Замовника_  ${dgfID}
  Ввести детальний опис_  ${description}
  Ввести назву організації_  ${procuringEntityName}
  Заповнити поле Лот виставляється на торги в_  ${tenderAttempts}
  Визначити мінімальну кількість учасників_  ${minNumberOfQualifiedBids}
  Заповнити данні позицій аукціону_  @{items}
  Заповнити поле гарантійного внеску_  ${guarantee_amount}
  Зберегти шаблон тендеру_
  Оголосити аукціон_
  ${return_value}  Get Text  xpath=(//div[@data-placeid='TENDER']//a[text()])[1]
  [Return]  ${return_value}

Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Шукає лот з uaid = tender_uaid. [Повертає] tender (словник з інформацією про лот)
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  tender

Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Оновлює сторінку з лотом для отримання потенційно оновлених даних.
  Open Browser  ${synchronization}  chrome
  Wait Until Page Contains  True  ${wait}
  Close Browser
  Switch Browser  ${browserAlias}
  Sleep  15  #testing
  Reload Page
  Run Keyword And Ignore Error  Select Frame  ${iframe}

Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  [Documentation]  Отримує значення поля field_name для лоту tender_uaid. [Повертає] tender['field_name'] (значення поля).
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  ${field_name}
  ${response}=  Отримати та обробити данні із тендера_  ${field_name}
  [Return]  ${response}

Внести зміни в тендер
  [Arguments]  ${user}  ${tenderId}  ${field}  ${value}
  [Documentation]  Змінює значення поля fieldname на fieldvalue для лоту tender_uaid.
  Pass Execution If  '${role}'=='provider' or '${role}'=='viewer'  Данний користувач не може вносити зміни в аукціон
  ${status}=  Run Keyword And Return Status  Location Should Contain  webclient
  Run Keyword If  '${status}' == '${False}'  smarttender.Знайти тендер власником_  ${user}  ${tenderId}
  Змінити дані тендера_  ${field}  ${value}

Отримати кількість документів в тендері
  [Arguments]  ${user}  ${tenderId}
  [Documentation]  Отримує кількість документів до лоту tender_uaid. [Повертає] number_of_documents (кількість доданих документів).
  Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
  ${documentNumber}=  Execute JavaScript  return (function(){return $("div.row.document").length-1;})()
  ${documentNumber}=  Convert To Integer  ${documentNumber}
  [Return]  ${documentNumber}

Скасувати закупівлю
  [Arguments]  ${user}  ${tenderId}  ${reason}  ${file}  ${descript}
  [Documentation]  Створює запит для скасування лоту tender_uaid, додає до цього запиту документ, який знаходиться по шляху document,
  ...  змінює опис завантаженого документа на new_description і переводить скасування закупівлі в статус active.
  ...  Цей ківорд реалізовуємо лише для процедур на цбд1.
  Pass Execution If  '${role}' == 'provider' or '${role}' == 'viewer'  Даний учасник не може скасувати тендер
  ${documents}=  create_fake_doc
  Підготуватися до редагування  ${user}  ${tenderId}
  Click Element  jquery=a[data-name='F2_________GPCANCEL']
  Wait Until Page Contains  Протоколи скасування
  Execute JavaScript  (function(){$("#cpModalMode table[data-name='reason'] input:eq(1)").val('');})()
  Input Text  jquery=#cpModalMode table[data-name='reason'] input:eq(1)    ${reason}
  Press Key  jquery=#cpModalMode table[data-name='reason'] input:eq(1)         \\13
  click element  xpath=//div[@title="Додати"]
  Choose File  id=fileUpload  ${file}
  Click Element  xpath=//*[@class="dxr-group mygroup"][1]
  Click Element  xpath=.//*[@data-type="TreeView"]//tbody/tr[2]
  Click Element  xpath=.//*[@data-type="TreeView"]//tbody/tr[2]
  Wait Until Page Contains  jquery=table[data-name='DocumentDescription'] input:eq(0)
  Input Text  jquery=table[data-name='DocumentDescription'] input:eq(0)    ${descript}
  Press Key  jquery=table[data-name='DocumentDescription'] input:eq(0)  \\13
  Click Element  jquery=a[title='OK']
  Wait Until Page Contains  аукціон буде
  Click Element  jquery=#IMMessageBoxBtnYes

Отримати посилання на аукціон для глядача
  [Arguments]  @{ARGUMENTS}
  [Documentation]  Отримує посилання на аукціон для лоту tender_uaid. [Повертає] auctionUrl (посилання).
  ...  ${username}  ${tender_uaid}  ${zero}
  smarttender.Пошук тендера по ідентифікатору  ${ARGUMENTS[0]}  ${ARGUMENTS[1]}
  ${href}=  Get Element Attribute  css=a#view-auction@href
  [Return]  ${href}

####################################
#      Робота з документами        #
####################################
Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  [Documentation]  Завантажує документ, який знаходиться по шляху filepath, до лоту tender_uaid користувачем username. [Повертає] reply (словник з інформацією про документ).
  Завантажити документ власником_  ${username}  ${filepath}  ${tender_uaid}
  [Teardown]  Закрити вікно редагування_

Завантажити документ в тендер з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${doc_type}
  [Documentation]  [Призначення] Завантажує документ, який знаходиться по шляху filepath і має певний documentType
  ...  (наприклад, x_nda, tenderNotice і т.д), до лоту tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про документ).
  Завантажити документ власником_  ${username}  ${filepath}  ${tender_uaid}
  Вибрати тип завантаженого документу_  ${doc_type}
  [Teardown]  Закрити вікно редагування_

Завантажити ілюстрацію
  [Arguments]    ${username}  ${tender_uaid}  ${filepath}
  [Documentation]  Завантажує ілюстрацію, яка знаходиться по шляху filepath
  ...  і має documentType = illustration, до лоту tender_uaid користувачем username.
  smarttender.Завантажити документ в тендер з типом  ${username}  ${tender_uaid}  ${filepath}  illustration

Завантажити фінансову ліцензію
  [Arguments]  ${user}  ${tenderId}  ${license_path}
  [Documentation]  Завантажує фінансову ліцензію, яка знаходиться по шляху filepath
  ...  і має documentType = financialLicense, до ставки лоту tender_uaid користувачем username.
  ...  Фінансова ліцензія вантажиться до ставок лише для лотів типу dgfFinancialAssets на цбд1.
  smarttender.Завантажити документ в ставку  ${user}  ${license_path}  ${tenderId}

Завантажити протокол аукціону
  [Arguments]  ${user}  ${tenderId}  ${filePath}  ${index}
  [Documentation]  Завантажує протокол аукціону, який знаходиться по шляху filepath
  ...  і має documentType = auctionProtocol, до ставки кандидата на кваліфікацію лоту tender_uaid користувачем username.
  ...  Ставка, до якої потрібно додавати аукціон протоколу визначається за award_index.
  ...  [Повертає] reply (словник з інформацією про документ).
  Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
  ${href}=  Get Element Attribute  jquery=div#auctionResults div.row.well:eq(${index}) a.btn.btn-primary@href
  Go To  ${href}
  Click Element  jquery=a.attachment-button:eq(0)
  ${hrefQualification}=  Get Element Attribute  jquery=a.attachment-button:eq(0)@href
  go to  ${hrefQualification}
  Choose File  jquery=input[name='fieldUploaderTender_TextBox0_Input']:eq(0)    ${filePath}
  Click Element  jquery=div#SubmitButton__1_CD
  Page Should Contain  Кваліфікаційні документи відправлені

Додати Virtual Data Room
  [Arguments]  ${user}  ${tenderId}  ${link}
  [Documentation]  Додає посилання на Virtual Data Room vdr_url з назвою title до лоту tender_uaid користувачем username.
  ...  Посилання на Virtual Data Room додається лише для лотів типу dgfFinancialAssets на цбд1.
  Знайти тендер власником_  ${user}  ${tenderId}
  Click Element  ${owner change}
  Wait Until Page Contains  Завантаження документації
  Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
  Wait Until Page Contains  jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)
  Input Text  jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)  ${link}
  Press Key  jquery=div#pcModalMode_PWC-1 table[data-name='VDRLINK'] input:eq(0)  \\13
  Click Image  jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img

Додати публічний паспорт активу
  [Arguments]  ${user}  ${tenderId}  ${link}
  [Documentation]  Додає посилання на публічний паспорт активу certificate_url з назвою title до лоту tender_uaid користувачем username.
  Знайти тендер власником_  ${user}  ${tenderId}
  Click Element  ${owner change}
  Wait Until Page Contains  Завантаження документації
  Click Element  jquery=#cpModalMode li.dxtc-tab:contains('Завантаження документації')
  Wait Until Page Contains  jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)
  Input Text  jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)  ${link}
  Press Key  jquery=div#pcModalMode_PWC-1 table[data-name='PACLINK'] input:eq(0)  \\13
  Click Image  jquery=#cpModalMode div.dxrControl_DevEx a:contains('Зберегти') img

Додати офлайн документ
  [Arguments]  ${user}  ${tenderId}  ${description}
  [Documentation]  Додає документ з назвою title, деталями доступу accessDetails
  ...  та строго визначеним documentType = x_dgfAssetFamiliarizationдо лоту tender_uaid користувачем username.
  Знайти тендер власником_  ${user}  ${tenderId}
  Підготуватися до редагування_
  Click Element  ${add files tab}
  Wait Until Page Contains Element  ${add file button}
  Input Text  xpath=(//*[@data-type="EditBox"])[last()]//textarea  ${description}
  [Teardown]  Закрити вікно редагування_

Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
  [Documentation]  Отримує значення поля field документа doc_id з лоту tender_uaid
  ...  для перевірки правильності відображення цього поля.
  ...  [Повертає] document['field'] (значення поля field)
  Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${isCancellation}=  Set Variable If  '${TEST NAME}' == 'Відображення опису документа до скасування лоту' or '${TEST NAME}' == 'Відображення заголовку документа до скасування лоту' or '${TEST NAME}' == 'Відображення вмісту документа до скасування лоту'  True  False
  Run Keyword If  ${isCancellation} == True  smarttender.Відкрити сторінку із данними скасування_
  ${result}=  Get Text  xpath=//span[contains(text(), '${doc_id}')]
  [Return]  ${result}

Отримати інформацію із документа по індексу
  [Arguments]  ${user}  ${tenderId}  ${doc_index}  ${field}
  [Documentation]  [Отримує значення поля field документа з індексом document_index з лоту tender_uaid
  ...  для перевірки правильності відображення цього поля.
  ...  [Повертає] field_value (значення поля field)
  ${result}=  Execute JavaScript  return(function(){ return $("div.row.document:eq(${doc_index+1}) span.info_attachment_type:eq(0)").text();})()
  ${resultDoctype}=  map_from_smarttender_document_type  ${result}
  [Return]  ${resultDoctype}

Отримати документ
  [Arguments]  ${user}  ${tenderId}  ${docId}
  [Documentation]  Завантажує файл з doc_id в заголовку з лоту tender_uaid в директорію ${OUTPUT_DIR}
  ...  для перевірки вмісту цього файлу.
  ...  [Повертає] filename (ім'я завантаженого файлу)
  Run Keyword  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
  ${selector}=  document_fields_info  content  ${docId}  False
  ${fileUrl}=  Get Element Attribute  jquery=div.row.document:contains('${docId}') a.info_attachment_link:eq(0)@href
  ${result}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
  smarttender_service.download_file  ${fileUrl}  ${OUTPUT_DIR}${/}${result}
  [Return]  ${result}

####################################
#     Робота з активами лоту       #
####################################
Додати предмет закупівлі
  [Arguments]  ${user}  ${tenderId}  ${item}
  [Documentation]  Додає дані про предмет item до лоту tender_uaid користувачем username.
  ${description}=  Get From Dictionary  ${item}  description
  ${quantity}=   Get From Dictionary  ${item}  quantity
  ${cpv}=  Get From Dictionary    ${item.classification}  id
  ${unit}=  Get From Dictionary  ${item.unit}  name
  ${unit}=  smarttender_service.convert_unit_to_smarttender_format  ${unit}
  smarttender.Підготуватися до редагування  ${user}  ${tenderId}
  click element  ${owner change}
  Wait Until Element Contains  jquery=#cpModalMode     Коригування  ${wait}
  Page Should Not Contain Element  jquery=#cpModalMode div.gridViewAndStatusContainer a[title='Додати']
  [Teardown]  Закрити вікно редагування_

Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${fieldname}
  [Documentation]  Отримує значення поля field_name з предмету з item_id в описі лоту tender_uaid.
  ...  [Повертає] item['field_name'] (значення поля).
  Fail  Temporary using keyword 'Отримати інформацію із тендера' until will be updated keyword 'Отримати інформацію із предмету'

Видалити предмет закупівлі
  [Arguments]  ${user}  ${tenderId}  ${itemId}
  [Documentation]  Видаляє з лоту tender_uaid предмет з item_id користувачем username.
  ${readyToEdit} =  Execute JavaScript  return(function(){return ((window.location.href).indexOf('webclient') !== -1).toString();})()
  Run Keyword If  '${readyToEdit}' != 'true'  Підготуватися до редагування  ${user}  ${tenderId}
  Click Element  ${owner change}
  Wait Until Element Contains  id=cpModalMode  Коригування  ${wait}
  Page Should Not Contain Element  jquery=#cpModalMode a[title='Удалить']
  [Teardown]  Закрити вікно редагування_

Отримати кількість предметів в тендері
  [Arguments]  ${user}  ${tenderId}
  [Documentation]  Отримує кількість активів лоту у лоті tender_uaid.
  ...  [Повертає] number_of_items (кількість активів лоту).
  smarttender.Пошук тендера по ідентифікатору  ${user}  ${tenderId}
  ${number_of_items}=  Get Element Count  xpath=//div[@id='home']//div[@class='well']
  [Return]  ${number_of_items}

####################################
# Запитання до лоту і активів лоту #
####################################
Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  [Documentation]  Створює запитання з даними question до активу лоту з item_id для лоту з tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про запитання).  discuss
  ${title}=  Get From Dictionary  ${question.data}  title
  ${description}=  Get From Dictionary  ${question.data}  description
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  questions
  ${question_data}=  Задати запитання_  ${title}  ${description}  ${item_id}
  [Return]  ${question_data}

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  [Documentation]  Створює запитання з даними question до лоту з tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про запитання).
  ${title}=  Get From Dictionary  ${question.data}  title
  ${description}=  Get From Dictionary  ${question.data}  description
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  questions
  ${question_data}=  Задати запитання_  ${title}  ${description}  no_id
  [Return]  ${question_data}

Отримати інформацію із запитання
  [Arguments]  ${user}  ${tenderId}  ${objectId}  ${field}
  [Documentation]  Отримує значення поля field_name із запитання з question_id в описі для тендера tender_uaid.
  ...  [Повертає] question['field_name'] (значення поля).
  Fail  it should not work
  ${selector}=  question_field_info  ${field}  ${objectId}
  Run Keyword And Ignore Error  Відкрити сторінку із даними запитань_
  ${ret}=  Execute JavaScript  return (function() { return $("${selector}").text() })()
  [Return]  ${ret}

Відповісти на запитання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  [Documentation]  Надає відповідь answer_data на запитання з question_id до лоту tender_uaid.
  ...  [Повертає] reply (словник з інформацією про відповідь).
  ${answerText}=  Get From Dictionary  ${answer_data.data}  answer
  Знайти тендер власником_  ${username}  ${tender_uaid}
  Відкрити закладку с запитаннями_
  Знайти запитання_  ${question_id}
  Відповісти на запитання та зберегти_  ${answerText}

####################################
#       Цінові пропозиції          #
####################################
Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  [Documentation]  Подає цінову пропозицію bid до лоту tender_uaid користувачем username.
  ...  [Повертає] reply (словник з інформацією про цінову пропозицію).
  ${amount}=  Get From Dictionary  ${bid.data.value}  amount
  ${amount}=  convert to string  ${amount}
  Пройти кваліфікацію для подачі пропозиції_  ${username}  ${tender_uaid}  ${bid}
  Прийняти участь в тендері_  ${username}  ${tender_uaid}  ${amount}
  ${response}=  Get Value  css=#lotAmount0>input
  ${response}=  smarttender_service.delete_spaces  ${response}
  [Return]  ${response}

Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  [Documentation]  Змінює поле fieldname на fieldvalue цінової пропозиції користувача username до лоту tender_uaid.
  ...  [Повертає] reply (словник з інформацією про цінову пропозицію)
  ${amount}=  convert to string  ${fieldvalue}
  Прийняти участь в тендері_  ${username}  ${tender_uaid}  ${amount}
  ${response}=  Get Value  css=#lotAmount0>input
  ${response}=  smarttender_service.delete_spaces  ${response}
  [Return]  ${response}

Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Змінює статус цінової пропозиції до лоту tender_uaid користувача username на cancelled.
  ...  [Повертає] reply (словник з інформацією про цінову пропозицію). Цей ківорд реалізовуємо лише для процедур на цбд1.
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  proposal
  Unselect Frame
  Wait Until Page Contains Element  ${cancellation offers button}
  Run Keyword And Ignore Error  Click Element  ${cancellation offers button}
  Run Keyword And Ignore Error  Click Element  ${cancel. offers confirm button}
  Run Keyword And Ignore Error  Click Element  ${ok button}

Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}
  [Documentation]  Завантажує документ типу doc_type, який знаходиться за шляхом path,
  ...  до цінової пропозиції користувача username для тендера tender_uaid.
  ...  [Повертає] reply (словник з інформацією про завантажений документ).
  Pass Execution If  '${mode}' == 'dgfOtherAssets'  Для типа 'Продаж майна банків, що ліквідуються' документы не вкладываются
  smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Page Contains Element  jquery=a#bid  ${wait}
  ${href}=  Get Element Attribute  jquery=a#bid@href
  Go To  ${href}
  Wait Until Page Contains  Пропозиція  10
  Wait Until Page Contains Element  jquery=button:contains('Обрати файли')  ${wait}
  Choose File  jquery=button:contains('Обрати файли')  ${path}
  Click Element  jquery=button#submitBidPlease
  Wait Until Page Contains Element  jquery=button:contains('Так')  ${wait}
  Click Element  jquery=button:contains('Так')
  Wait Until Page Contains  Пропозицію прийнято  ${wait}

Змінити документ в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${path}  ${docid}
  [Documentation]  Змінює документ з doc_id в пропозиції користувача username для лоту tender_uaid на документ,
  ...  який знаходиться по шляху path.
  ...  [Повертає] uploaded_file (словник з інформацією про завантажений документ).
  smarttender.Завантажити документ в ставку  ${username}  ${path}  ${tender_uaid}

Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  [Documentation]  Отримує значення поля field пропозиції користувача username для лоту tender_uaid.
  ...  [Повертає] bid['field'] (значення поля).
  smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${ret}=  smarttender.Отримати інформацію із тендера  ${username}  ${tender_uaid}  ${field}
  ${ret}=  Execute JavaScript  return (function() { return parseFloat('${ret}') })()
  [Return]  ${ret}

Отримати кількість документів в ставці
  [Arguments]  ${username}  ${tenderId}  ${bidIndex}
  [Documentation]  Отримує кількість документів у ціновій пропозиції з індексом bid_index до лоту tender_uaid.
  ...  [Повертає] number_of_documents (кількість доданих документів).
  #TODO удалить джаваскрипт, убить
  Run Keyword  smarttender.Підготуватися до редагування  ${username}  ${tenderId}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  ${normalizedIndex}=  normalize_index  ${bidIndex}  1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
  Wait Until Page Contains  Вкладення до пропозиції  ${wait}
  ${count}=  Execute JavaScript  return(function(){ var counter = 0;var documentSelector = $("#cpModalMode tr label:contains('Кваліфікація')").closest("tr");while (true) { documentSelector = documentSelector.next(); if(documentSelector.length == 0 || documentSelector[0].innerHTML.indexOf("label") === -1){ break;} counter = counter +1;} return counter;})()
  [Return]  ${count}

Отримати дані із документу пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}  ${document_index}  ${field}
  [Documentation]  Отримує значення поля field документу з індексом document_index пропозиції bid_index
  ...  користувача username для лоту tender_uaid.
  ...  [Повертає] field_value (значення поля).
  #TODO удалить джаваскрипт, убить
  Run Keyword  smarttender.Підготуватися до редагування  ${username}  ${tender_uaid}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  ${normalizedIndex}=  normalize_index  ${bid_index}  1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
  Wait Until Page Contains  Вкладення до пропозиції  ${wait}
  ${selectedType}=  Execute JavaScript  return(function(){ var startElement = $("#cpModalMode tr label:contains('Квалификации')"); var documentSelector = $(startElement).closest("tr").next(); if(${document_index} > 0){ for (i=0;i<=${document_index};i++) {documentSelector = $(documentSelector).next();}}if($(documentSelector).length == 0) {return "";} return "auctionProtocol";})()
  [Return]  ${selectedType}

Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}
  [Documentation]  Отримує посилання на участь в аукціоні для користувача username для лоту tender_uaid.
  ...  [Повертає] participationUrl (посилання).
  smarttender.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Page Contains Element  css=a#to-auction
  Click Element  css=a#to-auction
  Wait Until Page Contains Element  css=iframe#widgetIframe  ${wait}
  Select Frame  css=iframe#widgetIframe
  Wait Until Page Contains Element  jquery=a.link-button:eq(0)  ${wait}
  ${return_value}=  Get Element Attribute  jquery=a.link-button:eq(0)@href
  [Return]  ${return_value}
####################################
#     Кваліфікація кандидата       #
####################################
Завантажити документ рішення кваліфікаційної комісії
  [Arguments]  ${username}  ${file_path}  ${tender_uaid}  ${award_num}
  [Documentation]  Завантажує документ, який знаходиться по шляху file_path до кандидата під номером award_num для лоту tender_uaid.
  ...  [Повертає] doc (словник з інформацією про завантажений документ).
  Pass Execution If  '${role}' == 'provider' or '${role}' == 'viewer'  Даний учасник не може підтвердити постачальника
  Знайти тендер власником_  ${username}  ${tender_uaid}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  ${normalizedIndex}=  normalize_index  ${award_num}     1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
  Click Element  jquery=a[title='Кваліфікація']
  Click Element  xpath=//span[text()='Перегляд...']
  Choose File  ${choice file path}  ${file_path}
  Click Element  ${ok add file}

Підтвердити постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  [Documentation]  Переводить кандидата під номером award_num для лоту tender_uaid в статус active.
  ...  [Повертає] reply (словник з інформацією про кандидата).
  Pass Execution If  '${role}' == 'provider' or '${role}' == 'viewer'  Даний учасник не може підтвердити постачальника
  Підготуватися до редагування  ${username}  ${tender_uaid}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  ${normalizedIndex}=  normalize_index  ${award_num}  1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
  Click Element  jquery=a[title='Кваліфікація']
  Click Element  jquery=div.dxbButton_DevEx:contains('Підтвердити оплату')
  Click Element  jquery=div#IMMessageBoxBtnYes
  ${status}=   Execute JavaScript  return  (function() { return $("div[data-placeid='BIDS'] tr.rowselected td:eq(5)").text() } )()
  Should Be Equal  '${status}'  'Визначений переможцем'

Дискваліфікувати постачальника
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}  ${description}
  [Documentation]  Переводить кандидата під номером award_num для лоту tender_uaid в статус unsuccessful.
  ...  [Повертає] reply (словник з інформацією про кандидата).
  Підготуватися до редагування  ${username}  ${tender_uaid}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  ${normalizedIndex}=  normalize_index  ${award_num}  1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(1)
  Click Element  xpath=//a[@title="Кваліфікація"]
  Click Element  jquery=div.dxbButton_DevEx.dxbButtonSys.dxbTSys span:contains('Відхилити пропозицію')
  Click Element  id=IMMessageBoxBtnNo_CD
  Wait Until Page Contains  jquery=#cpModalMode textarea
  Input Text  jquery=#cpModalMode textarea  ${description}
  Click Element  xpath=//span[text()="Зберегти"]
  Click Element  id=IMMessageBoxBtnYes_CD

Скасування рішення кваліфікаційної комісії
  [Arguments]    ${username}    ${tender_uaid}    ${award_num}
  [Documentation]  Переводить кандидата під номером award_num для лоту tender_uaid в статус cancelled.
  ...  [Повертає] reply (словник з інформацією про кандидата).
  Pass Execution If  '${role}' == 'provider' or '${role}' == 'tender_owner'  Доступно тільки для другого учасника
  Run Keyword  smarttender.Пошук тендера по ідентифікатору    ${username}  ${tender_uaid}
  Click Element  jquery=div#auctionResults div.row.well:eq(${award_num}) div.btn.withdraw:eq(0)
  Select Frame  css=iframe#cancelPropositionFrame
  Click Element  id=firstYes
  Click Element  id=secondYes

####################################
#      Підписання контракту        #
####################################
Підтвердити підписання контракту
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}
  [Documentation]  Переводить договір під номером contract_num до лоту tender_uaid в статус active.
  smarttender.Підготуватися до редагування    ${ARGUMENTS[0]}     ${ARGUMENTS[1]}
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
  Click Element  jquery=a[title='Підписати договір']:eq(0)
  Click Element  jquery=#IMMessageBoxBtnYes_CD:eq(0)
  Click Element  jquery=#IMMessageBoxBtnOK:eq(0)

Завантажити угоду до тендера
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}  ${file_path}
  [Documentation]  Завантажує до контракту contract_num лоту tender_uaid документ,
  ...  який знаходиться по шляху filepath і має documentType = contractSigned, користувачем username.
  Run Keyword  smarttender.Підготуватися до редагування  ${username}  ${tender_uaid}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:contains('Визначений переможцем') td:eq(1)
  Click Element  jquery=a[title='Прикріпити договір']:eq(0)
  Wait Until Page Contains  Вкладення договірних документів
  Input Text  jquery=td.dxic input[maxlength='30']  11111111111111
  click element  xpath=//span[text()="Перегляд..."]
  Choose File  ${choice file path}  ${ARGUMENTS[3]}
  Click Element  ${ok add file}
  Click Element  jquery=a[title='OK']:eq(0)
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}


################################################
#            SMARTTENDER KEYWORDS              #
#            SMARTTENDER KEYWORDS              #
#            SMARTTENDER KEYWORDS              #
################################################
Login_
  [Arguments]  ${username}
  Click Element  ${open login button}
  Input Text  ${login field}  ${USERS.users['${username}'].login}
  Input Text  ${password field}  ${USERS.users['${username}'].password}
  Click Element  ${remember me}
  Click Element  ${login button}
  Run Keyword If  '${username}' != 'SmartTender_Owner'
  ...  Wait Until Page Contains  ${USERS.users['${username}'].login}  ${wait}
  ...  ELSE  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}

Click Input Enter Wait
  [Arguments]  ${locator}  ${text}
  Wait Until Page Contains Element  ${locator}
  Sleep  .2  # don't touch
  Click Element At Coordinates  ${locator}  10  5
  Input Text  ${locator}  ${text}
  Press Key  ${locator}  \\13
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Sleep  .3  # don't touch

Заповнити поле з ціною власником_
  [Arguments]  ${value}
  Click Input Enter Wait  css=#cpModalMode table[data-name='INITAMOUNT'] input  ${value}

Заповнити поле з мінімальним кроком аукіону_
  [Arguments]  ${value}
  Click Input Enter Wait  css=#cpModalMode table[data-name='MINSTEP'] input  ${value}

Заповнити поле гарантійного внеску_
  [Arguments]  ${value}
  Click Element  xpath=(//*[@id="cpModalMode"]//span[text()='Гарантійний внесок'])[1]
  Wait Until Element Is Visible    css=[data-name='GUARANTEE_AMOUNT']
  Click Input Enter Wait  css=#cpModalMode table[data-name='GUARANTEE_AMOUNT'] input  ${value}

Відкрити потрібну сторінку_
  [Arguments]  ${username}  ${tender_uaid}  ${page}
  [Documentation]  Відкриває сторінку location або оновлює поточну
  ...  tender
  ...  questions
  ...  cancellation
  ...  proposal
  ${page_needed}  ${page}=  location_converter  ${page}
  ${status}=  Run Keyword And Return Status  Location Should Contain  ${page_needed}
  Run keyword if  '${status}' == '${False}'  Відкрити сторінку ${page}_  ${tender_uaid}
  ...  ELSE  Run Keywords
  ...  Reload Page
  ...  AND  Run Keyword If  "${page}" == "tender" or "${page}" == "questions"
  ...  Select Frame  ${iframe}

Відкрити сторінку tender_
  [Arguments]  ${tender_uaid}
  ${status}=  Run Keyword And Return Status  Location Should Contain  auktsiony-na-prodazh-aktyviv-derzhpidpryemstv
  Run keyword if  '${status}' == '${False}'  Відкрити сторінку tender continue_  ${tender_uaid}

Відкрити сторінку tender continue_
  [Arguments]  ${tender_uaid}
  Go To  ${path to find tender}
  Wait Until page Contains Element  ${find tender field }  ${wait}
  Input Text  ${find tender field }  ${tender_uaid}
  Press Key  ${find tender field }  \\13
  Location Should Contain  f=${tender_uaid}
  ${href}=  Get Element Attribute  ${tender found}@href
  Go To  ${href}
  Select Frame  ${iframe}

Відкрити сторінку proposal_
  [Arguments]  ${tender_uaid}
  Wait Until Page Contains Element  css=a#bid
  ${href}=  Get Element Attribute  css=a#bid@href
  Go To  ${href}
  Wait Until Page Contains  Пропозиція по аукціону

Відкрити сторінку questions_
  [Arguments]  ${tender_uaid}
  Відкрити сторінку tender_  ${tender_uaid}
  Wait Until Page Contains Element  ${question_button}
  ${href}=  Get Element Attribute  ${question_button}@href
  Go to  ${href}
  Select Frame  ${iframe}

Відкрити сторінку cancellation_
  [Arguments]  ${tender_uaid}
  Click Element  jquery=a#cancellation:eq(0)
  Select Frame  jquery=#widgetIframe

Отримати та обробити данні із тендера_
  [Arguments]  ${fieldname}
  Run Keyword If  "${fieldname}" == "status"  smarttender.Оновити сторінку з тендером  1  1
  ${selector}=  auction_field_info  ${fieldname}
  ${value}=  Get Text  ${selector}
  ${value}=  Run Keyword If  "${fieldname}" == "tenderAttempts"  Crutch for get value from the page_  ${value}  ELSE  Set Variable  ${value}
  ${ret}=  convert_result  ${fieldname}  ${value}
  [Return]  ${ret}

Crutch for get value from the page_
  [Arguments]  ${value}
  ${value}=  Run Keyword If  '${value}' == 'Лот виставляється на торги повторно'  Execute JavaScript  return (function() {return $(".info_tenderAttempts").text() })()
  ...  ELSE IF  '${value}' == 'Лот виставляється на торги вперше'  Set Variable  1
  ...  ELSE  Set Variable  ${value}
  [Return]  ${value}

Змінити дані тендера_
  [Arguments]  ${field}  ${value}
  Підготуватися до редагування_
  ${value}=  convert to string  ${value}
  run keyword if  '${field}' == 'guarantee.amount'  Заповнити поле гарантійного внеску_  ${value}
  ...  ELSE IF  '${field}' == 'value.amount'  run keywords  Заповнити поле з ціною власником_  ${value}  AND  Заповнити поле з мінімальним кроком аукіону_  ${step_rate}
  ...  ELSE IF  '${field}' == 'minimalStep.amount'  Заповнити поле з мінімальним кроком аукіону_  ${value}
  ...  ELSE  Fail
  [Teardown]  Закрити вікно редагування_

Підготуватися до редагування_
  Click Element  ${owner change}
  Wait Until Page Contains Element  css=#pcModalMode_PW-1 .dxpc-headerText
  Wait Until Page Contains Element  ${correct tender button}  ${wait}
  Sleep  5  #don't touch
  Click Element  ${correct tender button}
  Sleep  3
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}

Знайти тендер власником_
  [Arguments]  ${USER}  ${TENDER_ID}
  Go To  ${USERS.users['${USER}'].homepage}
  Click Element  LoginAnchor
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Run Keyword And Ignore Error  Click Element  id=IMMessageBoxBtnNo_CD
  Wait Until Page Contains Element  ${orenda}
  Click Element  ${orenda}
  Wait Until Page Contains  Тестові аукціони на продаж
  Click Input Enter Wait  ${find tender_id field}  ${TENDER_ID}

Закрити вікно редагування_
  [Documentation]  Закриває вікно та ігнорує помилки
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Click Element  css=div.dxpnlControl_DevEx a[title='Зберегти'] img
  Закрити вікно з помилкою_

Закрити вікно з помилкою_
  Run Keyword And Ignore Error  Click Element  css=#IMMessageBoxBtnOK:nth-child(1)
  Run Keyword And Ignore Error  Click Element  xpath=//*[@id="cpModalMode"]//*[text()='Записати']
  Run Keyword And Ignore Error  Click Element  id=IMMessageBoxBtnOK_CD

Завантажити документ власником_
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  Підготуватися до редагування_
  Click Element  ${add files tab}
  Wait Until Page Contains Element  ${add file button}
  Click Element  ${add file button}
  Choose File  ${choice file path}  ${filepath}
  Click Element  ${ok add file}
  Wait Until Element Is Not Visible  ${ok add file}  15

Вибрати тип завантаженого документу_
  [Arguments]  ${doc_type}
  ${documentTypeNormalized}=  map_to_smarttender_document_type  ${doc_type}
  Click Element  xpath=(//*[text()="Інший тип"])[last()-1]
  Sleep  2
  Click Element  xpath=(//*[text()="Інший тип"])[last()-1]
  Sleep  2
  Click Element  css=td[class='cellselected editable']
  Sleep  1
  Click Element  xpath=(//*[contains(text(), "${documentTypeNormalized}")])[2]
  Sleep  .5
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Sleep  .5

Задати запитання_
  [Arguments]  ${title}  ${description}  ${item_id}
  Відкрити бланк запитання_  ${item_id}
  Заповнити динні для запитання_  ${title}  ${description}
  Закрити вікно ваше запитання успішно надіслане_
  #TODO  Don't know how to get value from the hidden element with Selenium2Library
  ${question_id}=  Execute JavaScript  return (function() {return $("span.question_idcdb").text() })()
  ${question_data}=  smarttender_service.get_question_data  ${question_id}
  [Return]  ${question_data}

Відкрити бланк запитання_
  [Arguments]  ${item_id}
  Wait Until Element Is Not Visible  ${wraploading}  ${wait}
  Run Keyword if  '${item_id}' == 'no_id'  Run Keywords
  ...  Click Element  css=#questions span[role="presentation"]
  ...  AND  Click Element  css=.select2-results li:nth-child(2)
  ...  AND  Click element  id=add-question
  ...  ELSE  Run Keywords
  ...  Click Element  jquery=#select2-question-relation-container:eq(0)
  ...  AND  Input Text  jquery=.select2-search__field:eq(0)  ${item_id}
  ...  AND  Press Key  jquery=.select2-search__field:eq(0)  \\13
  ...  AND  Click Element  jquery=input#add-question

Заповнити динні для запитання_
  [Arguments]  ${title}  ${description}
  Wait Until Element Is Not Visible  ${your request is sending}  ${wait}
  Select Frame  ${iframe}
  Input Text  id=subject  ${title}
  Input Text  id=question  ${description}
  Click Element  css=button[type='button']

Закрити вікно ваше запитання успішно надіслане_
  ${status}=  get text  css=.ivu-alert-message span
  Should Be Equal  ${status}  Ваше запитання успішно надіслане
  Unselect Frame
  Select Frame  ${iframe}
  Click Element  css=#inputFormQuestion i[onclick]

Пройти кваліфікацію для подачі пропозиції_
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  tender
  ${shouldQualify}=  Get Variable Value  ${bid['data'].qualified}
  Return From Keyword If  '${shouldQualify}' == '${False}'
  Wait Until Page Contains Element  jquery=a#participate  10
  ${lotId}=  Execute JavaScript  return(function(){return $("span.info_lotId").text()})()
  Click Element  jquery=a#participate
  Wait Until Page Contains Element  jquery=iframe#widgetIframe:eq(1)  ${wait}
  Select Frame  jquery=iframe#widgetIframe:eq(1)
  Wait Until Page Contains Element  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][1]//input  ${wait}
  Input Text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][1]//input  Іван
  Input Text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][2]//input  Іванов
  Input Text  xpath=.//*[@class="ivu-form-item"][2]//input  Іванович
  Input Text  xpath=.//*[@class="ivu-form-item ivu-form-item-required"][3]//input  +38011111111
  ${file_path}  ${file_name}  ${file_content}=  create_fake_doc
  Run Keyword And Ignore Error  Choose File  jquery=input#GUARAN  ${file_path}
  Run Keyword And Ignore Error  Choose File  jquery=input#FIN  ${file_path}
  Run Keyword And Ignore Error  Choose File  jquery=input#NOTDEP  ${file_path}
  Run Keyword And Ignore Error  Choose File  xpath=//input[@type="file"]  ${file_path}
  Click Element  xpath=//*[@class="group-line"]//input
  Click Element  xpath=//button[@class="ivu-btn ivu-btn-primary pull-right ivu-btn-large"]
  Unselect Frame
  Select Frame  ${iframe}
  Click Element  xpath=//*[@class="modal-dialog "]//*[ @class="close"]
  Open Browser  http://test.smarttender.biz/ws/webservice.asmx/ExecuteEx?calcId=_QA.ACCEPTAUCTIONBIDREQUEST&args={"IDLOT":"${lotId}","SUCCESS":"true"}&ticket=  chrome
  Wait Until Page Contains  True
  Close Browser
  Switch Browser  ${browserAlias}
  Reload Page
  Select Frame  ${iframe}

Прийняти участь в тендері_
  [Arguments]  ${username}  ${tender_uaid}  ${amount}
  Відкрити потрібну сторінку_  ${username}  ${tender_uaid}  proposal
  Заповнити дані для подачі пропозиції_  ${amount}
  Закрити валідаційне вікно_

Заповнити дані для подачі пропозиції_
  [Arguments]  ${value}
  Wait Until Page Contains Element  jquery=button#submitBidPlease
  Sleep  .5
  Run Keyword If  '${mode}' != 'dgfInsider'  Input Text  jquery=div#lotAmount0 input  ${value}
  Click Element  css=button#submitBidPlease
  Run Keyword And Ignore Error  Wait Until Page Contains Element  ${loading}
  Run Keyword And Ignore Error  Wait Until Element Is Not Visible  ${loading}  ${wait}

Закрити валідаційне вікно_
  Wait Until Page Contains  Пропозицію прийнято  ${wait}
  Wait Until Page Contains Element  css=div.ivu-modal-confirm-footer>button  ${wait}
  Click Element  css=div.ivu-modal-confirm-footer>button

####################################
#            WebClient             #
####################################

Відкрити вікно для створення тендера_
  Run Keyword And Ignore Error  Click Element  id=IMMessageBoxBtnNo_CD
  Wait Until Page Contains element  ${orenda}  ${wait}
  Click Element  ${orenda}
  Sleep  2  #don't touch
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Wait Until Page Contains element  ${create tender}
  Click Element  ${create tender}
  Wait Until Element Contains  cpModalMode  Оголошення  ${wait}

Вибрати тип процедури_
  Run Keyword If  '${mode}' != 'dgfOtherAssets'  Run Keywords
  ...  Run Keyword And Ignore Error
  ...     Click Element  css=[data-name='OWNERSHIPTYPE']
  ...  AND  Run Keyword And Ignore Error
  ...     Click Element  css=[data-name='KDM2']
  ...  AND  Run Keyword And Ignore Error
  ...     Click Element  css=div#CustomDropDownContainer div.dxpcDropDown_DevEx table:nth-child(3) tr:nth-child(2) td:nth-child(1)

Ввести дату старту аукціону_
  [Arguments]  ${auction_start}
  Click Input Enter Wait  css=#cpModalMode table[data-name='DTAUCTION'] input  ${auction_start}

З ПДВ_
  [Arguments]  ${valTax}
  Run Keyword If  ${valTax}  Click Element  css=table[data-name='WITHVAT'] span:nth-child(1)

Ввести загальну назву аукціону_
  [Arguments]  ${title}
  Click Input Enter Wait  css=#cpModalMode table[data-name='TITLE'] input  ${title}

Ввести номер лоту в Замовника_
  [Arguments]  ${dgfID}
  Click Input Enter Wait  css=#cpModalMode table[data-name='DGFID'] input:nth-child(1)  ${dgfID}

Ввести детальний опис_
  [Arguments]  ${description}
  Click Input Enter Wait  css=#cpModalMode table[data-name='DESCRIPT'] textarea  ${description}

Ввести назву організації_
  [Arguments]  ${procuringEntityName}
  Input Text  css=#cpModalMode div[data-name='ORG_GPO_2'] input  ${procuringEntityName}
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Press Key  css=#cpModalMode div[data-name='ORG_GPO_2'] input  \\09
  sleep  1  #don't touch
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Press Key  css=#cpModalMode div[data-name='ORG_GPO_2'] input  \\13
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Sleep  1  # don't touch

Заповнити поле Лот виставляється на торги в_
  [Arguments]  ${tenderAttempts}
  Click Element  css=#cpModalMode table[data-name='ATTEMPT'] input[type='text']
  Sleep  1  # don't touch
  Click Element  xpath=//*[text()="Невідомо"]/../following-sibling::tr[${tenderAttempts}]

Визначити мінімальну кількість учасників_
  [Arguments]  ${minNumberOfQualifiedBids}
  run keyword if  "${minNumberOfQualifiedBids}" == '1'  run keywords
  ...  Click Element  table[data-name='PARTCOUNT']
  ...  AND  click element  xpath=(//td[text()="1"])[last()]

Зберегти шаблон тендеру_
  Click Image  css=\#cpModalMode a[data-name="OkButton"] img
  Sleep  1  # don't touch
  Wait Until Element Is Not Visible    ${webClient loading}  ${wait}

Оголосити аукціон_
  Click Element  css=[data-name="TBCASE____SHIFT-F12N"]
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Wait Until Page Contains Element  id=IMMessageBoxBtnYes_CD
  Sleep  1  # don't touch
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Click Element  id=IMMessageBoxBtnYes_CD
  Wait Until Element Is Not Visible  id=IMMessageBoxBtnYes_CD
  Sleep  1  # don't touch
  Wait Until Element Is Not Visible    ${webClient loading}  ${wait}

Заповнити данні позицій аукціону_
  [Arguments]  @{items}
  Log Many  ${items}
  ${index}=  Set Variable  ${0}
  :FOR  ${item}  in  @{items}
  \  Run Keyword If  '${index}' != '0'  Click Element  css=div:nth-child(3) a[title='Додати']
  \  smarttender.Додати предмет в тендер_  ${item}
  \  ${index}=  SetVariable  ${index + 1}

Додати предмет в тендер_
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
  Ввести найменування позиції_  ${description}
  Вести кількість активів_  ${quantity}
  Ввести Од. вим._  ${unit}
  Ввести дата договору з_  ${contractPeriodendDate}
  Ввести дата договору по_  ${contractPeriodendDate}
  Вібрати класифікацію_  ${cpv/cav}
  Ввести id для класифікації_  ${cpv}
  Заповнити дані розташування об'єкту_  ${postalCode}  ${streetAddress}  ${locality}  ${latitude}  ${longitude}

Ввести найменування позиції_
  [Arguments]    ${description}
  Sleep  3  #don't touch
  Click Input Enter Wait  css=#cpModalMode div[data-name='KMAT'] input[type=text]:nth-child(1)  ${description}
  Sleep  2  #don't touch

Вести кількість активів_
  [Arguments]  ${quantity}
  Click Input Enter Wait  css=#cpModalMode table[data-name='QUANTITY'] input  ${quantity}

Ввести Од. вим._
  [Arguments]  ${unit}
  Click Input Enter Wait  css=#cpModalMode div[data-name='EDI'] input[type=text]:nth-child(1)  ${unit}

Ввести дата договору з_
  [Arguments]  ${contractPeriodendDate}
  Click Input Enter Wait  css=[data-name="CONTRFROM"] input  ${contractPeriodendDate}

Ввести дата договору по_
  [Arguments]  ${contractPeriodendDate}
  Click Input Enter Wait  css=[data-name="CONTRTO"] input  ${contractPeriodendDate}

Вібрати класифікацію_
  [Arguments]  ${cpv/cav}
  Click Element  css=[data-name="MAINSCHEME"]
  Run Keyword If  "${cpv/cav}" == "CAV" or "${cpv/cav}" == "CAV-PS"  Click Element  xpath=//td[text()="Класифікатор аукціонів держмайна"]
  ...  ELSE IF  "${cpv/cav}" == "CPV"  Click Element  xpath=//td[text()="CPV"]
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}

Ввести id для класифікації_
  [Arguments]  ${cpv}
  Click Input Enter Wait  css=#cpModalMode div[data-name='MAINCLASSIFICATION'] input[type=text]:nth-child(1)  ${cpv}

Заповнити дані розташування об'єкту_
  [Arguments]  ${postalCode}  ${streetAddress}  ${locality}  ${latitude}  ${longitude}
  Sleep  .5  #don't touch
  Click Input Enter Wait  css=#cpModalMode table[data-name='POSTALCODE'] input  ${postalCode}
  Click Input Enter Wait  css=#cpModalMode table[data-name='STREETADDR'] input  ${streetAddress}
  Click Input Enter Wait  css=#cpModalMode div[data-name='CITY_KOD'] input[type=text]:nth-child(1)  ${locality}
  Click Input Enter Wait  css=#cpModalMode table[data-name='LATITUDE'] input  ${latitude}
  Click Input Enter Wait  css=#cpModalMode table[data-name='LONGITUDE'] input  ${longitude}

Відповісти на запитання та зберегти_
  [Arguments]  ${answerText}
  Click Element  ${owner change}
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Wait Until Page Contains Element  ${answer field for question}
  Sleep  2
  Input Text  ${answer field for question}  ${answerText}
  Click Element  ${answer question checkbox}
  Sleep  .5
  Click Element  ${save changes}
  Sleep  .5
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Click Element  ${yes button}
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}
  Page Should Contain  ${answerText}

Відкрити закладку с запитаннями_
  Click Element  ${discuss tab}
  Wait Until Page Contains Element  ${discuss search field}

Знайти запитання_
  [Arguments]  ${question_id}
  Wait Until Page Contains  ${question_id}
  Input Text  ${discuss search field}  ${question_id}
  Press Key  ${discuss search field}  \\13
  Wait Until Element Is Not Visible  ${webClient loading}  ${wait}

####################################
#             LEGACY               #
####################################
Отримати текст із поля і показати на сторінці
  [Arguments]  ${fieldname}
  wait until page contains element  ${wait}
  ${return_value}=  Get Text  ${locator.${fieldname}}${locator.${fieldname}}
  [Return]  ${return_value}

Підтвердити наявність протоколу аукціону
  [Arguments]  ${user}  ${tenderId}  ${bidIndex}
  Run Keyword  smarttender.Підготуватися до редагування  ${user}  ${tenderId}
  Click Element  jquery=#MainSted2TabPageHeaderLabelActive_1
  ${normalizedIndex}=  normalize_index  ${bidIndex}  1
  Click Element  jquery=div[data-placeid='BIDS'] div.objbox.selectable.objbox-scrollable table tbody tr:eq(${normalizedIndex}) td:eq(2)
  Wait Until Page Contains Element  xpath=//*[@data-name="OkButton"]  ${wait}
  Click Element  xpath=//*[@data-name="OkButton"]

Завантажити протокол аукціону в авард
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${award_index}
  smarttender.Завантажити документ рішення кваліфікаційної комісії  ${username}  ${filepath}  ${tender_uaid}  ${award_index}
  Click Element  jquery=div.dxbButton_DevEx:eq(2)
  Click Element  xpath=//span[text()="Зберегти"]
  Click Element  id=IMMessageBoxBtnYes_CD