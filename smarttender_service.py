﻿# coding=utf-8
from munch import munchify as smarttender_munchify
from iso8601 import parse_date
from dateutil.parser import parse
from dateutil.parser import parserinfo
from pytz import timezone
import urllib2
import os
import re

TZ = timezone(os.environ['TZ'] if 'TZ' in os.environ else 'Europe/Kiev')
number_of_tabs = 1

def tender_field_info(field):
    if "items" in field:
        list = re.search('(?P<items>\w+)\[(?P<id>\d)\]\.(?P<map>.+)', field)
        item_id = int(list.group('id')) + 1
        result = list.group('map')
        map = {
            "description": "xpath=//*[@class='table-items'][{0}]//td[1]",
            "deliveryDate.startDate": "xpath=(//*[@class='smaller-font'])[{0}]/div[3]",
            "deliveryDate.endDate": "xpath=(//*[@class='smaller-font'])[{0}]/div[3]",
            "deliveryLocation.latitude": "xpath=(//*[@class='smaller-font']//a)[{0}]@href",
            "deliveryLocation.longitude": "xpath=(//*[@class='smaller-font']//a)[{0}]@href",
            "classification.scheme": "xpath=(//*[@class='smaller-font']/div[1])[{0}]",
            "classification.id": "xpath=(//*[@class='smaller-font']/div[1])[{0}]",
            "classification.description": "xpath=(//*[@class='smaller-font']/div[1])[{0}]",
            "unit.name": "xpath=(//*[@class='text-lot'])[{0}]",
            "unit.code": "xpath=(//*[@class='text-lot'])[{0}]",
            "quantity": "xpath=(//*[@class='text-lot'])[{0}]",
            "additionalClassifications[0].scheme": "xpath=(//*[@class='smaller-font']/div[1])[{0}]",
            "additionalClassifications[0].id": "xpath=(//*[@class='smaller-font']/div[1])[{0}]",
            "additionalClassifications[0].description": "xpath=(//*[@class='smaller-font']/div[1])[{0}]",
            "deliveryAddress.countryName": "xpath=(//div[@id='tooltipID']//td[@class='smaller-font']//div[4])[{0}]",
            "deliveryAddress.postalCode": "xpath=(//div[@id='tooltipID']//td[@class='smaller-font']//div[4])[{0}]",
            "deliveryAddress.region": "xpath=(//div[@id='tooltipID']//td[@class='smaller-font']//div[4])[{0}]",
            "deliveryAddress.locality": "xpath=(//div[@id='tooltipID']//td[@class='smaller-font']//div[4])[{0}]",
            "deliveryAddress.streetAddress": "xpath=(//div[@id='tooltipID']//td[@class='smaller-font']//div[4])[{0}]",
        }
        return map[result].format(item_id)
    elif "lots" in field:
        list = re.search('(?P<lots>\w+)\[(?P<id>\d)\]\.(?P<map>.+)', field)
        lot_id = int(list.group('id')) + 1
        result = list.group('map')
        map = {
            "minimalStep.valueAddedTaxIncluded": "css=[class=price]",
            "minimalStep.amount": "css=[class='price text-lot']",
        }
        return map[result].format(lot_id)
    elif "features" in field:
        list = re.search('(?P<features>\w+)\[(?P<id>\d)\]\.(?P<map>.+)', field)
        features_id = int(list.group('id')) + 1
        result = list.group('map')
        map = {
            "title": "xpath=//*[@class='text-lot criteria-tip'][{0}]",
            "description": "xpath=//*[@class='text-lot criteria-tip'][{0}]",
            "featureOf": "xpath=//*[@class='text-lot criteria-tip'][{0}]",
        }
        return map[result].format(features_id)
    elif "questions" in field:
        question_id = int(re.search("\d", field).group(0)) + 4
        result = ''.join(re.split(r'].', ''.join(re.findall(r'\]\..+', field))))
        map = {
            "title": "xpath=(//*[@id='questions']/div/div[{0}]//span)[1]",
            "description": "xpath=//*[@id='questions']/div/div[{0}]//div[@class='q-content']",
            "answer": "xpath=//*[@id='questions']/div/div[{0}]//div[@class='answer']/div[3]"
        }
        return (map[result]).format(question_id)
    elif "awards" in field:
        list = re.search('(?P<documents>\w+)\[(?P<id>\d)\]\.(?P<map>.+)', field)
        award_id = int(list.group('id')) + 1
        result = list.group('map')
        map = {
            # "status": "css=div#auctionResults div.row.well:nth-child({0}) h5",
            "status": "xpath=//table[@class='table-proposal'][{0}]//td[3]",
            "documents[0].title": "xpath=(//*[@class='attachment-row']//*[@class='fileLink'])[{0}]",
            "suppliers[0].contactPoint.telephone": "xpath=//table[@class='table-proposal'][{0}]//td[1]/div/div[4]/span",
            "suppliers[0].contactPoint.name": "xpath=//table[@class='table-proposal'][{0}]//td[1]/div/div[2]/span",
            "suppliers[0].contactPoint.email": "xpath=//table[@class='table-proposal'][{0}]//td[1]/div/div[3]/span",
            "suppliers[0].identifier.legalName": "xpath=//*[@class='table-proposal'][{0}]//div[@class='organization']",
            "suppliers[0].identifier.id": "xpath=//table[@class='table-proposal'][{0}]//td[1]/div/div[1]/span",
            "suppliers[0].name": "xpath=//*[@class='table-proposal'][{0}]//div[@class='organization']",
            "value.amount": "xpath=//table[@class='table-proposal'][{0}]//td[2]",
            "value.currency": "xpath=//table[@class='table-proposal'][1]//tr/th[2]",
            "complaintPeriod.endDate": "css=span",
        }
        return map[result].format(award_id)
    elif "documents" in field:
        list = re.search('(?P<documents>\w+)\[(?P<id>\d)\]\.(?P<map>.+)', field)
        document_id = int(list.group('id')) + 1
        result = list.group('map')
        map = {
            "title": "css=a.fileLink[href]",
        }
        return map[result].format(document_id)
    else:
        map = {
            "title": "css=.info_orderItem",
            "title_en": "css=.info_orderItem",
            "title_ru": "css=.info_orderItem",
            "description": "css=.info_info_comm2",
            "description_en": "css=.info_info_comm2",
            "value.amount": "css=[class=price]",
            "value.currency": "css=[class=price]",
            "value.valueAddedTaxIncluded": "css=[class=price]",
            "tenderID": "css=.info_tendernum",
            "procuringEntity.name": "css=.group-element .pop",
            "enquiryPeriod.startDate": "css=.info_enquirysta",
            "enquiryPeriod.endDate": "css=.info_ddm",
            "tenderPeriod.startDate": "css=.info_tenderingFrom",
            "tenderPeriod.endDate": "css=.info_tenderingTo",
            "minimalStep.amount": "css=[class='price text-lot']",
            "status": "xpath=//*[@id='group-main']/div[3]",
            "qualificationPeriod.endDate": u"xpath=(//div[contains(text(), 'Прекваліфікация')])[last()]",
            "auctionPeriod.startDate": "css=#home span.info_dtauction",
            "auctionPeriod.endDate": "css=#home span.info_dtauctionEnd",
            "procurementMethodType": "xpath=//*[@class='table price']/following::div[1]//dl/dd[1]",
            "guarantee.amount": "xpath=(//*[@class='table-responsive']//td[2])[3]",
            "minNumberOfQualifiedBids": "css=.info_minnumber_qualifiedbids",
            "dgfID": "css=.page-header h4:nth-of-type(2)",
            "auctionID": "css=.page-header h3:nth-of-type(3)",
            "tenderAttempts": "css=.page-header>div>h4",
            "procuringEntity.contactPoint.name": "css=.info_contact div:nth-child(1)",
            "procuringEntity.contactPoint.telephone": "css=.info_contact div:nth-child(2)",
            "procuringEntity.identifier.legalName": "css=span.pop",
            "procuringEntity.identifier.id": "css=span.info_usreou",
            "procuringEntity.contactPoint.url": "css=.info_contact div:nth-child(2)",
            "lotValues[0].value.amount": "css=#lotAmount0>input",
            "cancellations[0].reason": "css=span.info_cancellation_reason",
            "cancellations[0].status": "css=span.info_cancellation_status",
            "eligibilityCriteria": "css=span.info_eligibilityCriteria",
            "contracts[0].status": "xpath=//table[@class='table-proposal'][1]//td[3]",

            "procuringEntity.address.countryName": "css=td.smaller-font div:nth-child(4)",
            "procuringEntity.address.locality": "css=td.smaller-font div:nth-child(4)",
            "procuringEntity.address.postalCode": "css=td.smaller-font div:nth-child(4)",
            "procuringEntity.address.region": "css=td.smaller-font div:nth-child(4)",
            "procuringEntity.address.streetAddress": "css=span",

            "dgfDecisionID": "css=span.info_dgfDecisionId",
            "dgfDecisionDate": "css=span.info_dgfDecisionDate",


            "qualificationPeriod": "css=span",
            "causeDescription": "css=span",
            "cause": "css=span",
            "procuringEntity.identifier.scheme": "css=span",
        }
    return map[field]

def proposal_field_info(field):
    map = {
        "lotValues[0].value.amount": "css=#lotAmount0>input",
        "value.amount": "css=#lotAmount0>input",
        "status": "css=.ivu-alert-desc span",
    }
    return map[field]

def lot_field_info(field, id):
    map = {
        "title": "xpath=//*[contains(text(), '{0}')]",
        "description": "xpath=//*[contains(text(), '{0}')]",
        "value.amount": "css=[class=price]",
        "value.currency": "css=[class=price]",
        "value.valueAddedTaxIncluded": "css=[class=price]",
        "minimalStep.amount": "css=[class='price text-lot']",
        "minimalStep.currency": "css=[class='price text-lot']",
        "minimalStep.valueAddedTaxIncluded": "css=[class=price]",

    }
    return map[field].format(id)

def item_field_info(field, id):
    map = {
        "description": "xpath=//*[@class='table-items']//td[contains(text(), '{0}')]",
    }
    return map[field].format(id)

def non_price_field_info(field, id):
    map = {
        "title": "xpath=//*[contains(text(), '{0}')]",
        "description": "xpath=//*[contains(text(), '{0}')]@title",
        "featureOf": "xpath=//*[contains(text(), '{0}')]/preceding-sibling::div[@class='title-lot  cr-title'][1]",
    }
    return map[field].format(id)

def document_fields_info(field, id):
    map = {
        "title": "xpath=//*[contains(text(), '{0}')]",

        "description": "span.info_attachment_description:eq(0)",
        "content": "span.info_attachment_title:eq(0)",
        "type": "span.info_attachment_type:eq(0)",
    }
    return map[field].format(id)

def question_field_info(field, id):
    map = {

        "description": "xpath=//span[contains(text(),'{0}')]/../following-sibling::div[@class='q-content']",
        "title": "div.title-question span.question-title-inner",
        "answer": "div.answer div:eq(2)"
    }
    return (map[field]).format(id)

def claim_field_info(field, title):
    map = {
        "title": u"xpath=//*[contains(text(), '{0}')]/../../../*[@data-qa='title']/div[1]/span[1]",
        "status": u"xpath=//*[contains(text(), '{0}')]/../../../*[@data-qa='type-status']/div",
        "description": u"xpath=//*[contains(text(), '{0}')]/../../..//span[@data-qa='description']",
        "cancellationReason": u"xpath=//*[contains(text(), '{0}')]/../../..//*[@data-qa='events']//div[@class='content break-word']",
        "resolutionType": u"xpath=//*[contains(text(), 'Тип рішення: ')]/span",
        "resolution": u"xpath=//*[contains(text(), 'Тип рішення: ')]/../*[@class='content break-word']",
        "satisfied": u"xpath=//*[contains(text(), 'Участник дал ответ на решение организатора')]/../../..//*[@class='content break-word']",
    }
    return map[field].format(title)

def convert_claim_result_from_smarttender(value):
    map = {
        u"Вимога": "claim",
        u"Отменена жалобщиком": 'invalid',
        u"Дана відповідь": "answered",
        u"Вирішена": "resolved",
        u"Вирішено": "resolved",
        u"Відхилена": 'cancelled',
        u"Не задоволена": "declined",
        u"Вимога задовільнена": True,
        u"Вимога не задовільнена": False,
    }
    if value in map:
        result = map[value]
    else:
        result = value
    return result

def claim_file_field_info(field, doc_id):
    map = {
        "title": u"xpath=//*[contains(text(), '{0}')]",
    }
    return map[field].format(doc_id)

def convert_result(field, value):
    global ret
    if 'awards' in field and 'value.amount' in field:
        ret = delete_spaces(value)
    elif "amount" in field:
        ret = float(re.sub(u'[^\d.]', '', ''.join(re.findall(u'[\d\s.]+\sгрн', value))))
    elif "procurementMethodType" in field:
        if u"Оренда" in value:
            ret = 'dgfOtherAssets'
    elif "valueAddedTaxIncluded" in field:
        if u'ПДВ' in value:
            ret = True
        else:
            ret = value
    elif "currency" in field:
        if u'грн.' in value:
            ret = "UAH"
        else:
            ret = value
    elif "unit" in field or "quantity" in field:
        list = re.search(u'(?P<count>[\d,.]+?)\s(?P<name>.+)', value)
        if 'quantity' in field:
            ret = int(list.group('count'))
        else:
            ret = list.group('name')
        if 'code' in field:
            ret = convert_unit_from_smarttender_format(ret, 'code')
        elif 'name' in field:
            ret = convert_unit_from_smarttender_format(ret, 'name')
    elif "quantity" in field:
        ret = re.search(u'(?P<count>[\d,.]+?)\s(?P<name>.+)', value).group('count')
    elif "additionalClassifications" in field:
        ret = ''.join(re.findall(u'[^\(][^\)]', ''.join(re.findall(u'\(.+\)', value))))
    elif "contractPeriod.startDate" in field \
            or "contractPeriod.endDate" in field \
            or "auctionPeriod.startDate" in field \
            or "auctionPeriod.endDate" in field:
        ret = convert_date(value)
    elif "qualificationPeriod.endDate" in field:
        list = re.search(u'(?P<data>[\d\.]+\s[\d\:]+)', value)
        ret = list.group('data')
        ret = convert_date(ret)
    elif "minNumberOfQualifiedBids" in field \
            or "tenderAttempts" in field:
        ret = int(value)
    elif "dgfDecisionDate" in field:
        ret = convert_date_offset_naive(value)
    elif "quantity" in field:
        ret = re.search(u'(?P<count>[\d,.]+?)\s(?P<name>.+)', value).group('count')
    elif "classification" in field:
        list = re.search(u'Код\s(?P<scheme>.+?):\s(?P<id>.+?)\s—\s(?P<description>.+)', value)
        if 'scheme' in field:
            ret = list.group('scheme')
        elif 'id' in field:
            ret = list.group('id')
        elif 'description' in field:
            ret = list.group('description')
            if ret == u'Не визначено':
                ret = u'Не відображене в інших розділах'
    elif "status" in field or "awards." in field:
        ret = convert_tender_status(value)
    elif "enquiryPeriod.startDate" == field or "enquiryPeriod.endDate" == field or "tenderPeriod.startDate" == field \
            or "tenderPeriod.endDate" in field:
        value = str(''.join(re.findall(r"\d{2}.\d{2}.\d{4} \d{2}:\d{2}", value)))
        ret = convert_date(value)
    elif "deliveryDate.startDate" in field:
        value = re.findall(u"\d{2}.\d{2}.\d{4}", value)
        ret = value[0]
        ret = convert_date(ret)
    elif "deliveryDate.endDate" in field:
        value = re.findall(u"\d{2}.\d{2}.\d{4}", value)
        ret = value[1]
        ret = convert_date(ret)
    elif "deliveryLocation" in field:
        value = re.findall(r'\d{2}.\d+', value)
        if 'latitude' in field:
            ret = value[0]
        elif 'longitude' in field:
            ret = value[1]
    elif 'featureOf' in field:
        if u'Критерії для лоту' in value:
            ret = 'lot'
        elif u'Критерії для закупівлі' in value:
            ret = 'tenderer'
        elif u'Критерії для номенклатури' in value:
            ret = 'item'
        else:
            ret = False
    elif 'deliveryAddress' in field:
        list = re.search(
            u'Адреса постачання\: '
            u'(?P<postalCode>\d+?), (?P<countryName>.+?), (?P<region>.+?), (?P<locality>.+?), (?P<streetAddress>.+)',
            value)
        if 'postalCode' in field:
            ret = list.group('postalCode')
        elif 'countryName' in field:
            ret = list.group('countryName')
        elif 'region' in field:
            ret = list.group('region')
        elif 'locality' in field:
            ret = list.group('locality')
        elif 'streetAddress' in field:
            ret = list.group('streetAddress')
    else:
        ret = value
    return ret

def convert_unit_to_smarttender_format(unit):
    map = {
        u"кілограми": u"кг",
        u"послуга": u"умов.",
        u"умов.": u"умов.",
        u"усл.": u"умов.",
        u"метри квадратні": u"м.кв.",
        u"м.кв.": u"м.кв.",
        u"шт": u"шт"
    }
    return map[unit]

def convert_unit_from_smarttender_format(unit, field):
    map = {
        u"шт": {"code": "H87", "name": u"шт"},
        u"кг": {"code": "KGM", "name": u"кілограми"},
        u"умов.": {"code": "E48", "name": u"послуга"},
        u"м.кв.": {"code": "MTK", "name": u"метри квадратні"},
        u"упаков": {"code": "PK", "name": u"упаковка"},
        u"лот": {"code": "LO", "name": u"лот"},
        u"флак.": {"code": "VI", "name": u"Флакон"},

        u"пара": {"code": "PR", "name": u"пара"},
        u"літр": {"code": "LTR", "name": u"літр"},
        u"набір": {"code": "SET", "name": u"набір"},
        u"пачок": {"code": "NMP", "name": u"пачок"},
        u"метри": {"code": "MTR", "name": u"метри"},
        u"метри кубічні": {"code": "MTQ", "name": u"метри кубічні"},
        u"ящик": {"code": "BX", "name": u"ящик"},
        u"рейс": {"code": "E54", "name": u"рейс"},
        u"тони": {"code": "TNE", "name": u"тони"},
        u"кілометри": {"code": "KMT", "name": u"кілометри"},
        u"місяць": {"code": "MON", "name": u"місяць"},
        u"пачка": {"code": "RM", "name": u"пачка"},
        u"упаковка": {"code": "PK", "name": u"упаковка"},
        u"гектар": {"code": "HAR", "name": u"гектар"},
        u"блок": {"code": "D64", "name": u"блок"},
    }
    return map[unit][field]

def convert_tender_status(value):
    map = {
        u"Прийом пропозицій": "active.tendering",
        u"Аукціон": "active.auction",
        u"Кваліфікація": "active.qualification",
        u"Оплачено, очікується підписання договору": "active.awarded",
        u"Торги не відбулися": "unsuccessful",
        u"Завершено": "complete",
        u"Торги скасовано": "cancelled",
        u"Ваша раніше подана пропозиція у статусі «Недійсне». Необхідно підтвердження": "invalid",
        u"Очікує дискваліфікації першого учасника": "pending.waiting",
        u"Рішення скасовано": "cancelled",
        u"Очікує підтвердження протоколу": "pending.verification",
        u"Очікується оплата": "pending.payment",
        u"Переможець": "active",
        u"Переможе": "pending",
        u"Дискваліфікований": "unsuccessful",
        u"Період уточнень": "active.enquiries",
    }
    return map[value]

def convert_claim_status(value):
    map = {
        "Відхилена": 'cancelled'
    }
    return map[value]

def convert_datetime_to_smarttender_format(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y %H:%M")
    return date_string

def convert_datetime_to_kot_format(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y %H:%M:%S")
    return date_string

def convert_datetime_to_smarttender_form(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y")
    return date_string

def convert_date_offset_naive(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%d')

def convert_date(s):
    dt = parse(s, parserinfo(True, False))
    return dt.strftime('%Y-%m-%dT%H:%M:%S+03:00')

def adapt_data(tender_data):
    tender_data.data.procuringEntity[
        'name'] = u"ФОНД ГАРАНТУВАННЯ ВКЛАДІВ ФІЗИЧНИХ ОСІБ"
    tender_data.data.procuringEntity['identifier'][
        'legalName'] = u"ФОНД ГАРАНТУВАННЯ ВКЛАДІВ ФІЗИЧНИХ ОСІБ"
    tender_data.data.procuringEntity['identifier']['id'] = u"111111111111111"
    tender_data.data['items'][0].deliveryAddress.locality = u"Київ"
    for item in tender_data.data['items']:
        if item.unit['name'] == u"послуга":
            item.unit['name'] = u"усл."
        elif item.unit['name'] == u"метри квадратні":
            item.unit['name'] = u"м.кв."
        elif item.unit['name'] == u"штуки":
            item.unit['name'] = u"шт"
    for item in tender_data.data['items']:
        if item.deliveryAddress['region'] == u"місто Київ":
            item.deliveryAddress['region'] = u"Київська обл."
        elif item.deliveryAddress['locality'] == u"Дніпро":
            item.deliveryAddress['locality'] = u"Кривий ріг"
    return tender_data

def get_question_data(id):
    return smarttender_munchify({'data': {'id': id}})

def map_to_smarttender_document_type(doctype):
    map = {
        u"x_presentation": u"Презентація",
        u"tenderNotice": u"Паспорт торгів",
        u"x_nda": u"Договір NDA",
        u"technicalSpecifications": u"Публічний паспорт активу",
        u"financial_documents": u"Цінова пропозиція",
        u"qualification_documents": u"Документи, що підтверджують кваліфікацію",
        u"eligibility_documents": u"Документи, що підтверджують відповідність",
    }
    return map[doctype]

def map_from_smarttender_document_type(doctype):
    map = {
        u"Презентація": u"x_presentation",
        u"Паспорт торгів": u"tenderNotice",
        u"Договір NDA": u"x_nda",
        u"Технические спецификации": u"technicalSpecifications",
        u"Порядок ознайомлення з майном/активом у кімнаті даних": u"x_dgfAssetFamiliarization",
        u"Посиланння на Публічний Паспорт Активу": u"x_dgfPublicAssetCertificate",
        u"Місце та форма прийому заявок на участь, банківські реквізити для зарахування гарантійних внесків":
            u"x_dgfPlatformLegalDetails",
        u"\u2015": u"none",
        u"Ілюстрація": u"illustration",
        u"Віртуальна кімната": u"vdr",
        u"Публічний паспорт активу": u"x_dgfPublicAssetCertificate"
    }
    return map[doctype]

def location_converter(value):
    if "cancellation" in value:
        response = "/cancellation/", "cancellation"
    elif "questions" in value:
        response = "/discuss/", "questions"
    elif "proposal" in value:
        response = "/bid/edit/", "proposal"
    elif "awards" in value and "documents" in value:
        response = "/webparts/", "awards"
    elif "claims" in value:
        response = "/AppealNew/", "claims"
    elif "multiple_items" in value:
        response = "/webparts/", "multiple_items"
    else:
        response = "/publichni-zakupivli-prozorro/", "tender"
    return response

def download_file(url, download_path):
    response = urllib2.urlopen(url)
    file_content = response.read()
    open(download_path, 'a').close()
    f = open(download_path, 'w')
    f.write(file_content)
    f.close()

def normalize_index(first, second):
    if first == "-1":
        return "2"
    else:
        return str(int(first) + int(second))

def delete_spaces(value):
    return float(''.join(re.findall(r'\S', value)))

def get_attribute(value):
    if 'latitude' in value or 'longitude' in value:
        return True
    elif 'features' in value and 'description' in value:
        return True
    else:
        return False

def synchronization(string):
    list = re.search(u'{"DateStart":"(?P<date_start>[\d\s\:\.]+?)",'
                     u'"DateEnd":"(?P<date_end>[\d\s\:\.]*?)",'
                     u'"WorkStatus":"(?P<work_status>[\w+]+?)",'
                     u'"Success":(?P<success>[\w+]+?)}', string)
    date_start = list.group('date_start')
    date_end = list.group('date_end')
    work_status = list.group('work_status')
    success = list.group('success')
    return date_start, date_end, work_status, success
