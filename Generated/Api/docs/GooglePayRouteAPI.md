# GooglePayRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**googlePay**](GooglePayRouteAPI.md#googlepay) | **POST** /google_pay | 


# **googlePay**
```swift
    open class func googlePay(id: UUID, purchaseToken: String, userId: String, credit: Int64? = nil, loaded: Bool? = nil, orderId: String? = nil, packageName: String? = nil, productId: String? = nil, status: Status? = nil, completion: @escaping (_ data: GooglePay?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let id = 987 // UUID | 
let purchaseToken = "purchaseToken_example" // String | 
let userId = "userId_example" // String | 
let credit = 987 // Int64 |  (optional)
let loaded = true // Bool |  (optional)
let orderId = "orderId_example" // String |  (optional)
let packageName = "packageName_example" // String |  (optional)
let productId = "productId_example" // String |  (optional)
let status = Status() // Status |  (optional)

GooglePayRouteAPI.googlePay(id: id, purchaseToken: purchaseToken, userId: userId, credit: credit, loaded: loaded, orderId: orderId, packageName: packageName, productId: productId, status: status) { (response, error) in
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
 **id** | **UUID** |  | 
 **purchaseToken** | **String** |  | 
 **userId** | **String** |  | 
 **credit** | **Int64** |  | [optional] 
 **loaded** | **Bool** |  | [optional] 
 **orderId** | **String** |  | [optional] 
 **packageName** | **String** |  | [optional] 
 **productId** | **String** |  | [optional] 
 **status** | [**Status**](Status.md) |  | [optional] 

### Return type

[**GooglePay**](GooglePay.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

