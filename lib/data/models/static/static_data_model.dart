// Package imports:
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

// Project imports:
import 'package:invoiceninja_flutter/data/models/company_model.dart';
import 'package:invoiceninja_flutter/data/models/e_invoice_model.dart';
import 'package:invoiceninja_flutter/data/models/static/country_model.dart';
import 'package:invoiceninja_flutter/data/models/static/currency_model.dart';
import 'package:invoiceninja_flutter/data/models/static/date_format_model.dart';
import 'package:invoiceninja_flutter/data/models/static/industry_model.dart';
import 'package:invoiceninja_flutter/data/models/static/invoice_status_model.dart';
import 'package:invoiceninja_flutter/data/models/static/language_model.dart';
import 'package:invoiceninja_flutter/data/models/static/payment_type_model.dart';
import 'package:invoiceninja_flutter/data/models/static/size_model.dart';
import 'package:invoiceninja_flutter/data/models/static/timezone_model.dart';

part 'static_data_model.g.dart';

abstract class StaticDataListResponse
    implements Built<StaticDataListResponse, StaticDataListResponseBuilder> {
  factory StaticDataListResponse(
          [void updates(StaticDataListResponseBuilder b)]) =
      _$StaticDataListResponse;

  StaticDataListResponse._();

  @override
  @memoized
  int get hashCode;

  BuiltList<StaticDataEntity> get data;

  static Serializer<StaticDataListResponse> get serializer =>
      _$staticDataListResponseSerializer;
}

abstract class StaticDataItemResponse
    implements Built<StaticDataItemResponse, StaticDataItemResponseBuilder> {
  factory StaticDataItemResponse(
          [void updates(StaticDataItemResponseBuilder b)]) =
      _$StaticDataItemResponse;

  StaticDataItemResponse._();

  @override
  @memoized
  int get hashCode;

  StaticDataEntity get data;

  static Serializer<StaticDataItemResponse> get serializer =>
      _$staticDataItemResponseSerializer;
}

class StaticDataFields {
  static const String currencies = 'currencies';
  static const String sizes = 'sizes';
  static const String industries = 'industries';
  static const String timezones = 'timezones';
  static const String dateFormats = 'date_formats';
  static const String languages = 'languages';
  static const String paymentTypes = 'payment_types';
  static const String countries = 'countries';
  static const String invoiceDesigns = 'invoice_designs';
  static const String invoiceStatus = 'invoice_status';
  static const String frequencies = 'frequencies';
  static const String gateways = 'gateways';
  static const String gatewayTypes = 'gateway_types';
  static const String fonts = 'fonts';
  static const String bulkUpdates = 'bulk_updates';
}

abstract class StaticDataEntity
    implements Built<StaticDataEntity, StaticDataEntityBuilder> {
  factory StaticDataEntity() {
    return _$StaticDataEntity._(
      currencies: BuiltList<CurrencyEntity>(),
      sizes: BuiltList<SizeEntity>(),
      industries: BuiltList<IndustryEntity>(),
      gateways: BuiltList<GatewayEntity>(),
      timezones: BuiltList<TimezoneEntity>(),
      dateFormats: BuiltList<DateFormatEntity>(),
      languages: BuiltList<LanguageEntity>(),
      paymentTypes: BuiltList<PaymentTypeEntity>(),
      countries: BuiltList<CountryEntity>(),
      invoiceStatus: BuiltList<InvoiceStatusEntity>(),
      templates: BuiltMap<String, TemplateEntity>(),
      bulkUpdates: BuiltMap<String, BuiltList<String>>(),
      eInvoiceSchema: BuiltMap<String, EInvoiceFieldEntity>(),
    );
  }

  StaticDataEntity._();

  @override
  @memoized
  int get hashCode;

  BuiltList<CurrencyEntity> get currencies;

  BuiltList<SizeEntity> get sizes;

  BuiltList<IndustryEntity> get industries;

  BuiltList<TimezoneEntity> get timezones;

  BuiltList<GatewayEntity> get gateways;

  @BuiltValueField(wireName: 'date_formats')
  BuiltList<DateFormatEntity> get dateFormats;

  BuiltList<LanguageEntity> get languages;

  @BuiltValueField(wireName: 'payment_types')
  BuiltList<PaymentTypeEntity> get paymentTypes;

  BuiltList<CountryEntity> get countries;

  @BuiltValueField(wireName: 'invoice_status')
  BuiltList<InvoiceStatusEntity> get invoiceStatus;

  @BuiltValueField(wireName: 'bulk_updates')
  BuiltMap<String, BuiltList<String>> get bulkUpdates;

  BuiltMap<String, TemplateEntity> get templates;

  @BuiltValueField(wireName: 'einvoice_schema')
  BuiltMap<String, EInvoiceFieldEntity> get eInvoiceSchema;

  // ignore: unused_element
  static void _initializeBuilder(StaticDataEntityBuilder builder) => builder
    ..bulkUpdates.replace(BuiltMap<String, List<String>>())
    ..eInvoiceSchema.replace(BuiltMap<String, EInvoiceFieldEntity>());

  static Serializer<StaticDataEntity> get serializer =>
      _$staticDataEntitySerializer;
}

abstract class TemplateEntity
    implements Built<TemplateEntity, TemplateEntityBuilder> {
  factory TemplateEntity() {
    return _$TemplateEntity._(
      subject: '',
      body: '',
    );
  }

  TemplateEntity._();

  @override
  @memoized
  int get hashCode;

  String get subject;

  String get body;

  static Serializer<TemplateEntity> get serializer =>
      _$templateEntitySerializer;
}
