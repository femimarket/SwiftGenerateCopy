# UploadRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**upload**](UploadRouteAPI.md#upload) | **POST** /upload | 


# **upload**
```swift
    open class func upload(credit: Int64, file: String, id: UUID, userId: String, completion: @escaping (_ data: Upload?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let credit = 987 // Int64 | 
let file = "file_example" // String | 
let id = 987 // UUID | uuid v7
let userId = "userId_example" // String | 

UploadRouteAPI.upload(credit: credit, file: file, id: id, userId: userId) { (response, error) in
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
 **file** | **String** |  | 
 **id** | **UUID** | uuid v7 | 
 **userId** | **String** |  | 

### Return type

[**Upload**](Upload.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

