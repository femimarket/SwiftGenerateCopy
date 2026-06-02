# StripeRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**stripe**](StripeRouteAPI.md#stripe) | **POST** /stripe | 


# **stripe**
```swift
    open class func stripe(userId: String, byColumn: StripeByColumn? = nil, byFields: StripeByFields? = nil, byId: StripeById? = nil, delete: StripeDelete? = nil, paginate: StripePaginate? = nil, search: StripeSearch? = nil, update: StripeUpdate? = nil, upsert: StripeUpsert? = nil, completion: @escaping (_ data: StripeServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = stripe.ByColumn(column: "column_example", data: [Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example")], value: 123) // StripeByColumn |  (optional)
let byFields = stripe.ByFields(data: [Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example")], fields: [stripe.ByFieldsQuery(path: "path_example", value: "value_example")]) // StripeByFields |  (optional)
let byId = stripe.ById(data: Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example"), id: 123) // StripeById |  (optional)
let delete = stripe.Delete(data: [123]) // StripeDelete |  (optional)
let paginate = stripe.Paginate(data: [Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example")], skip: 123, take: 123) // StripePaginate |  (optional)
let search = stripe.Search(data: [Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example")], query: "query_example") // StripeSearch |  (optional)
let update = stripe.Update(data: [Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example")], inputs: [stripe.UpdateItem(fields: "TODO", id: 123)]) // StripeUpdate |  (optional)
let upsert = stripe.Upsert(data: [Model(amountCents: 123, credit: 123, id: 123, loaded: false, paymentUrl: "paymentUrl_example", status: Status(), stripePaymentIntentId: "stripePaymentIntentId_example", stripeSessionId: "stripeSessionId_example", userId: "userId_example")]) // StripeUpsert |  (optional)

StripeRouteAPI.stripe(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String** |  | 
 **byColumn** | [**StripeByColumn**](StripeByColumn.md) |  | [optional] 
 **byFields** | [**StripeByFields**](StripeByFields.md) |  | [optional] 
 **byId** | [**StripeById**](StripeById.md) |  | [optional] 
 **delete** | [**StripeDelete**](StripeDelete.md) |  | [optional] 
 **paginate** | [**StripePaginate**](StripePaginate.md) |  | [optional] 
 **search** | [**StripeSearch**](StripeSearch.md) |  | [optional] 
 **update** | [**StripeUpdate**](StripeUpdate.md) |  | [optional] 
 **upsert** | [**StripeUpsert**](StripeUpsert.md) |  | [optional] 

### Return type

[**StripeServerRequest**](StripeServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

