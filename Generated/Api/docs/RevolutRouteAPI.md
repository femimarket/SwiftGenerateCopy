# RevolutRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**revolut**](RevolutRouteAPI.md#revolut) | **POST** /revolut | 


# **revolut**
```swift
    open class func revolut(amountCents: Int64, id: UUID, status: Status, userId: String, credit: Int64? = nil, loaded: Bool? = nil, paymentUrl: String? = nil, revolutOrderId: String? = nil, completion: @escaping (_ data: Revolut?, _ error: Error?) -> Void)
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
let revolutOrderId = "revolutOrderId_example" // String |  (optional)

RevolutRouteAPI.revolut(amountCents: amountCents, id: id, status: status, userId: userId, credit: credit, loaded: loaded, paymentUrl: paymentUrl, revolutOrderId: revolutOrderId) { (response, error) in
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
 **revolutOrderId** | **String** |  | [optional] 

### Return type

[**Revolut**](Revolut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

