# ApplePayRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**applePay**](ApplePayRouteAPI.md#applepay) | **POST** /apple_pay | 


# **applePay**
```swift
    open class func applePay(credit: Int64, currency: String, id: UUID, jws: String, loaded: Bool, price: Int64, productId: String, status: ApplePayStatus, transactionId: String, userId: String, completion: @escaping (_ data: ApplePay?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let credit = 987 // Int64 | 
let currency = "currency_example" // String | 
let id = 987 // UUID | uuid v7
let jws = "jws_example" // String | 
let loaded = true // Bool | 
let price = 987 // Int64 | 
let productId = "productId_example" // String | 
let status = ApplePayStatus() // ApplePayStatus | 
let transactionId = "transactionId_example" // String | 
let userId = "userId_example" // String | 

ApplePayRouteAPI.applePay(credit: credit, currency: currency, id: id, jws: jws, loaded: loaded, price: price, productId: productId, status: status, transactionId: transactionId, userId: userId) { (response, error) in
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
 **credit** | **Int64** |  | 
 **currency** | **String** |  | 
 **id** | **UUID** | uuid v7 | 
 **jws** | **String** |  | 
 **loaded** | **Bool** |  | 
 **price** | **Int64** |  | 
 **productId** | **String** |  | 
 **status** | [**ApplePayStatus**](ApplePayStatus.md) |  | 
 **transactionId** | **String** |  | 
 **userId** | **String** |  | 

### Return type

[**ApplePay**](ApplePay.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

