# ApplePayRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**applePay**](ApplePayRouteAPI.md#applepay) | **POST** /apple_pay | 


# **applePay**
```swift
    open class func applePay(userId: String, byColumn: ApplePayByColumn? = nil, byFields: ApplePayByFields? = nil, byId: ApplePayById? = nil, delete: ApplePayDelete? = nil, paginate: ApplePayPaginate? = nil, search: ApplePaySearch? = nil, update: ApplePayUpdate? = nil, upsert: ApplePayUpsert? = nil, completion: @escaping (_ data: ApplePayServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = apple_pay.ByColumn(column: "column_example", data: [ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example")], value: 123) // ApplePayByColumn |  (optional)
let byFields = apple_pay.ByFields(data: [ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example")], fields: [apple_pay.ByFieldsQuery(path: "path_example", value: "value_example")]) // ApplePayByFields |  (optional)
let byId = apple_pay.ById(data: ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example"), id: 123) // ApplePayById |  (optional)
let delete = apple_pay.Delete(data: [123]) // ApplePayDelete |  (optional)
let paginate = apple_pay.Paginate(data: [ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example")], skip: 123, take: 123) // ApplePayPaginate |  (optional)
let search = apple_pay.Search(data: [ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example")], query: "query_example") // ApplePaySearch |  (optional)
let update = apple_pay.Update(data: [ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example")], inputs: [apple_pay.UpdateItem(fields: "TODO", id: 123)]) // ApplePayUpdate |  (optional)
let upsert = apple_pay.Upsert(data: [ApplePay(credit: 123, currency: "currency_example", id: 123, jws: "jws_example", loaded: false, price: 123, productId: "productId_example", status: ApplePayStatus(), transactionId: "transactionId_example", userId: "userId_example")]) // ApplePayUpsert |  (optional)

ApplePayRouteAPI.applePay(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**ApplePayByColumn**](ApplePayByColumn.md) |  | [optional] 
 **byFields** | [**ApplePayByFields**](ApplePayByFields.md) |  | [optional] 
 **byId** | [**ApplePayById**](ApplePayById.md) |  | [optional] 
 **delete** | [**ApplePayDelete**](ApplePayDelete.md) |  | [optional] 
 **paginate** | [**ApplePayPaginate**](ApplePayPaginate.md) |  | [optional] 
 **search** | [**ApplePaySearch**](ApplePaySearch.md) |  | [optional] 
 **update** | [**ApplePayUpdate**](ApplePayUpdate.md) |  | [optional] 
 **upsert** | [**ApplePayUpsert**](ApplePayUpsert.md) |  | [optional] 

### Return type

[**ApplePayServerRequest**](ApplePayServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

