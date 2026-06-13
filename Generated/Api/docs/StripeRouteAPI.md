# StripeRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**stripe**](StripeRouteAPI.md#stripe) | **POST** /stripe | 


# **stripe**
```swift
    open class func stripe(amountCents: Int64, id: UUID, status: Status, userId: String, credit: Int64? = nil, loaded: Bool? = nil, paymentUrl: String? = nil, stripePaymentIntentId: String? = nil, stripeSessionId: String? = nil, completion: @escaping (_ data: Model?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let amountCents = 987 // Int64 | 
let id = 987 // UUID | 
let status = Status() // Status | 
let userId = "userId_example" // String | 
let credit = 987 // Int64 |  (optional)
let loaded = true // Bool |  (optional)
let paymentUrl = "paymentUrl_example" // String |  (optional)
let stripePaymentIntentId = "stripePaymentIntentId_example" // String |  (optional)
let stripeSessionId = "stripeSessionId_example" // String |  (optional)

StripeRouteAPI.stripe(amountCents: amountCents, id: id, status: status, userId: userId, credit: credit, loaded: loaded, paymentUrl: paymentUrl, stripePaymentIntentId: stripePaymentIntentId, stripeSessionId: stripeSessionId) { (response, error) in
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
 **amountCents** | **Int64** |  | 
 **id** | **UUID** |  | 
 **status** | [**Status**](Status.md) |  | 
 **userId** | **String** |  | 
 **credit** | **Int64** |  | [optional] 
 **loaded** | **Bool** |  | [optional] 
 **paymentUrl** | **String** |  | [optional] 
 **stripePaymentIntentId** | **String** |  | [optional] 
 **stripeSessionId** | **String** |  | [optional] 

### Return type

[**Model**](Model.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

