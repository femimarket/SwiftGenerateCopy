# WiseRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**wise**](WiseRouteAPI.md#wise) | **POST** /wise | 


# **wise**
```swift
    open class func wise(amountCents: Int64, currency: String, id: UUID, reference: String, status: Status, userId: String, credit: Int64? = nil, loaded: Bool? = nil, wiseCreditId: String? = nil, completion: @escaping (_ data: Wise?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let amountCents = 987 // Int64 | 
let currency = "currency_example" // String | 
let id = 987 // UUID | 
let reference = "reference_example" // String | 
let status = Status() // Status | 
let userId = "userId_example" // String | 
let credit = 987 // Int64 |  (optional)
let loaded = true // Bool |  (optional)
let wiseCreditId = "wiseCreditId_example" // String |  (optional)

WiseRouteAPI.wise(amountCents: amountCents, currency: currency, id: id, reference: reference, status: status, userId: userId, credit: credit, loaded: loaded, wiseCreditId: wiseCreditId) { (response, error) in
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
 **currency** | **String** |  | 
 **id** | **UUID** |  | 
 **reference** | **String** |  | 
 **status** | [**Status**](Status.md) |  | 
 **userId** | **String** |  | 
 **credit** | **Int64** |  | [optional] 
 **loaded** | **Bool** |  | [optional] 
 **wiseCreditId** | **String** |  | [optional] 

### Return type

[**Wise**](Wise.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

