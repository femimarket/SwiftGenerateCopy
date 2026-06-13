# SummaryRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**summary**](SummaryRouteAPI.md#summary) | **POST** /summary | 


# **summary**
```swift
    open class func summary(credit: Int64, id: UUID, text: String, userId: String, completion: @escaping (_ data: Summary?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let credit = 987 // Int64 | 
let id = 987 // UUID | 
let text = "text_example" // String | On input: the text (e.g. lyrics) to summarise. On output / when stored: the AI-generated vibe summary. Server overwrites client-supplied value once vLLM responds.
let userId = "userId_example" // String | 

SummaryRouteAPI.summary(credit: credit, id: id, text: text, userId: userId) { (response, error) in
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
 **id** | **UUID** |  | 
 **text** | **String** | On input: the text (e.g. lyrics) to summarise. On output / when stored: the AI-generated vibe summary. Server overwrites client-supplied value once vLLM responds. | 
 **userId** | **String** |  | 

### Return type

[**Summary**](Summary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

