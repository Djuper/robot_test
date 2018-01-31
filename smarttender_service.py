from munch import munchify as smarttender_munchify
from iso8601 import parse_date
from dateutil.parser import parse
from dateutil.parser import parserinfo
from datetime import datetime
from pytz import timezone
import urllib2
import os
import string
import re

TZ = timezone(os.environ['TZ'] if 'TZ' in os.environ else 'Europe/Kiev')
number_of_tabs = 1

def auction_field_info(field):
    if "items" in field:
        item_id = int(re.search("\d", field).group(0))+ 1
        splitted = field.split(".")
        splitted.remove(splitted[0])
        result = string.join(splitted, '.')
        map = {
            "description": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//h5",
            "unit.name": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//h5",
            "quantity": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//h5",
            "unit.code": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//h5",
            "contractPeriod.startDate": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//dd[last()]",
            "contractPeriod.endDate": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//dd[last()]",
            "classification.scheme": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//dd[1]",
            "classification.id": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//dd[1]",
            "classification.description": "xpath=(//*[@id='home']//*[@class='row well'])[{0}]//dd[1]",
            "additionalClassifications[0].description": "xpath=//*[@class='table price']/following::div[1]//dl/dd[1]",

            "additionalClassifications[0].scheme": "1css=span[data-itemid]:nth-child({0}) .info_DKPP",
            "additionalClassifications[0].id": "1css=span[data-itemid]:nth-child({0}) .info_dkpp_code",
        }
        return (map[result]).format(item_id)
    elif "questions" in field:
        question_id = int(re.search("\d",field).group(0))+ 4
        result = ''.join(re.split(r'].', ''.join(re.findall(r'\]\..+', field))))
        map = {
            "title": "xpath=(//*[@id='questions']/div/div[{0}]//span)[1]",
            "description": "xpath=//*[@id='questions']/div/div[{0}]//div[@class='q-content']",
            "answer": "xpath=//*[@id='questions']/div/div[{0}]//div[@class='answer']/div[3]"
        }
        return (map[result]).format(question_id)
    elif "awards" in field:
        award_id = int(re.search("\d",field).group(0)) + 1
        result = ''.join(re.split(r'].', ''.join(re.findall(r'\]\..+', field))))
        map = {
            "status": "css=div#auctionResults div.row.well:nth-child({0}) h5 span"
        }
        return map[result].format(award_id)
    else:
        map = {
            "value.amount": "xpath=(//*[@class='table-responsive']//td[2])[1]",
            "value.currency": "xpath=(//*[@class='table-responsive']//td[2])[1]",
            "value.valueAddedTaxIncluded": "xpath=(//*[@class='table-responsive']//td[2])[1]",
            "tenderPeriod.endDate": "xpath=(//*[@class='popover-content timeline-popover'])[2]//div",
            "minimalStep.amount": "xpath=(//*[@class='table-responsive']//td[2])[2]",
            "procurementMethodType": "xpath=//*[@class='table price']/following::div[1]//dl/dd[1]",
            "procurementMethodType": "xpath=//*[@class='table price']/following::div[1]//dl/dd[1]",
            "guarantee.amount": "xpath=(//*[@class='table-responsive']//td[2])[3]",
            "title": "css=.page-header h3:nth-of-type(2)",
            "minNumberOfQualifiedBids": "css=.info_minnumber_qualifiedbids",
            "dgfID": "css=.page-header h4:nth-of-type(2)",
            "description": "css=.page-header span",
            "auctionID": "css=.page-header h3:nth-of-type(3)",
            "procuringEntity.name": "xpath=//*[@class='table-responsive']/following-sibling::*[@class='row']//dd[2]/span",
            "status": "css=.page-header div:nth-child(2) h4",
            "tenderAttempts": "css=.page-header>div>h4",

            "enquiryPeriod.startDate": "1css=span.info_enquirysta",
            "enquiryPeriod.endDate": "1css=span.info_ddm",
            "tenderPeriod.startDate": "1css=span.info_enquirysta",
            "auctionPeriod.startDate": "1css=span.info_dtauction",
            "auctionPeriod.endDate": "1css=span.info_dtauctionEnd",
            "cancellations[0].reason": "1css=span.info_cancellation_reason",
            "cancellations[0].status": "1css=span.info_cancellation_status",
            "eligibilityCriteria": "1css=span.info_eligibilityCriteria",
            "contracts[-1].status": "1css=span.info_contractStatus",
            "dgfDecisionID": "1css=span.info_dgfDecisionId",
            "dgfDecisionDate": "1css=span.info_dgfDecisionDate"
        }
    return map[field]

def convert_result(field, value):
    if field == "value.amount" \
            or field == "guarantee.amount" \
            or field == "minimalStep.amount":
        ret = float(re.sub(ur'[^\d.]', '', ''.join(re.findall(ur'[\d\s.]+\sгрн', value))))
    elif field ==  "procurementMethodType":
        if u"Оренда" in value:
            ret = 'dgfOtherAssets'
    elif field == "value.valueAddedTaxIncluded":
        if u'ПДВ' in value:
            ret = True
        else:
            ret = value
    elif field == "value.currency":
        if u'грн.' in value:
            ret = "UAH"
        else:
            ret = value
    elif "unit.code" in field:
        value = ''.join(re.findall(ur'\м.кв.|\шт|\умов.|\кг', value))
        ret = convert_edi_from_starttender_format(value)
    elif "classification.description" in field:
        ret = ''.join(re.split(ur'— ', ''.join(re.findall(ur'\—\s.+', value))))
    elif "additionalClassifications" in field:
        ret = ''.join(re.findall(ur'[^\(][^\)]', ''.join(re.findall(ur'\(.+\)', value))))
    elif "unit.name" in field:
        value =  ''.join(re.split(r' ', ''.join(re.findall(ur'\W+$', value))))
        ret = convert_unit_from_smarttender_format(value)
    elif "tenderPeriod.endDate" in field:
        ret = str(''.join(re.findall(r"\d{2}.\d{2}.\d{4} \d{2}:\d{2}", value)))
        ret = convert_date(ret)
    elif "contractPeriod.startDate" in field \
            or "contractPeriod.endDate" in field \
            or "tenderPeriod.startDate" in field \
            or "auctionPeriod.startDate" in field:
        ret = convert_date(value)
    elif "minNumberOfQualifiedBids" in field \
            or "tenderAttempts" in field:
        ret = int(value)
    elif "dgfDecisionDate" in field:
        ret = convert_date_offset_naive(value)
    elif "quantity" in field:
        ret = float(''.join(re.findall(ur'\d+\.\d+', value)))
    elif "description" in field:
        if "questions" in field:
            ret = value
        else:
            ret = ''.join(re.findall(ur'\s+[\d.]+\s[\W\w\D\d. ]*', value))
            ret = re.sub(ret, '', value)
    elif "classification.scheme" in field:
        ret = ''.join(re.split(r':', ''.join(re.findall(ur'.+\:', value))))
    elif "classification.id" in field:
        ret = ''.join(re.split(ur': ', ''.join(re.findall(ur'\:\s[\d\-]+', value))))
    elif "status" == field or "awards" in field:
        ret = convert_tender_status(value)
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

def convert_tender_status(value):
    map = {
        u"Прийом пропозицій": "active.tendering",
        u"Аукціон": "active.auction",
        u"Кваліфікація": "active.qualification",
        u"": "active.awarded",
        u"Торги не відбулися": "unsuccessful",
        u"Завершено": "complete",
        u"": "cancelled",

        u"Очікує дискваліфікації першого учасника": "pending.waiting",
        u"": "cancelled",
        u"Очікує підтвердження протоколу": "pending.verification",
        u"Очікується оплата": "pending.payment",
        u"Переможець": "active",
        u"Дискваліфікований": "unsuccessful",
    }
    return map[value]

def convert_edi_from_starttender_format(edi):
    map = {
        u"кг": u"KGM",
        u"умов.": u"E48",
        u"м.кв.": u"MTK",
        u"шт": u"H87"
    }
    return map[edi]

def convert_unit_from_smarttender_format(unit):
    map = {
        u"кг": u"кілограми",
        u"умов.": u"усл.",
        u"усл.": u"усл.",
        u"м.кв.": u"м.кв.",
        u"шт": u"шт"
    }
    return map[unit]

def convert_datetime_to_smarttender_format(isodate):
    iso_dt = parse_date(isodate)
    date_string = iso_dt.strftime("%d.%m.%Y %H:%M")
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
    return dt.strftime('%Y-%m-%dT%H:%M:%S+02:00')

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
    return tender_data

def get_question_data(id):
    return smarttender_munchify({'data': {'id': id}})

def document_fields_info(field,docId,is_cancellation_document):
    map = {
        "description": "span.info_attachment_description:eq(0)",
        "title": "span.info_attachment_title:eq(0)",
        "title1": ".fileLink:eq(0)",
        "content": "span.info_attachment_title:eq(0)",
        "type": "span.info_attachment_type:eq(0)"
    }
    if str(is_cancellation_document) == "True":
        result = map[field]
    else:
        result = ("div.row.document:contains('{0}') ".format(docId))+map[field]
    return result

def map_to_smarttender_document_type(doctype):
    map = {
        u"x_presentation": u"Презентація",
        u"tenderNotice": u"Паспорт торгів",
        u"x_nda": u"Договір NDA",
        u"technicalSpecifications": u"Публічний паспорт активу",
        u"x_dgfAssetFamiliarization": u"",
        u"x_dgfPublicAssetCertificate": u""
    }
    return map[doctype]

def map_from_smarttender_document_type(doctype):
    map = {
        u"Презентація" : u"x_presentation",
        u"Паспорт торгів" : u"tenderNotice",
        u"Договір NDA": u"x_nda",
        u"Технические спецификации": u"technicalSpecifications",
        u"Порядок ознайомлення з майном/активом у кімнаті даних": u"x_dgfAssetFamiliarization",
        u"Посиланння на Публічний Паспорт Активу": u"x_dgfPublicAssetCertificate",
        u"Місце та форма прийому заявок на участь, банківські реквізити для зарахування гарантійних внесків": u"x_dgfPlatformLegalDetails",
        u"\u2015": u"none",
        u"Ілюстрація": u"illustration",
        u"Віртуальна кімната": u"vdr",
        u"Публічний паспорт активу": u"x_dgfPublicAssetCertificate"
    }
    return map[doctype]

def location_converter(value):
    if "cancellation" in value:
        ret = "cancellation", "cancellation"
    elif "questions" in value:
        ret = "discuss", "questions"
    elif "proposal" in value:
        ret = "/bid/edit/", "proposal"
    else:
        ret = "auktsiony-na-prodazh-aktyviv-derzhpidpryemstv", "tender"
    return ret

def question_field_info(field, id):
    map = {
        "description": "xpath=//span[contains(text(),'{0}')]/../following-sibling::div[@class='q-content']",
        "title": "div.title-question span.question-title-inner",
        "answer": "div.answer div:eq(2)"
    }
    return (map[field]).format(id)

def download_file(url,download_path):
    response = urllib2.urlopen(url)
    file_content = response.read()
    open(download_path, 'a').close()
    f = open(download_path, 'w')
    f.write(file_content)
    f.close()

def normalize_index(first,second):
    if first == "-1":
        return "2"
    else:
        return str(int(first) + int(second))

def delete_spaces(value):
    return float(''.join(re.findall(r'\S', value)))