
# Compatibility Report

![semver MINOR](https://img.shields.io/badge/semver-MINOR-orange?logo=semver "semver MINOR")

## Summary

> [!WARNING]
>
> Compatible changes found while checking backward compatibility of version `1.6.0` with the previous version `1.5`.

<details markdown="1">
<summary>Expand to see options used.</summary>

- **Report only summary**: No
- **Report only changes**: Yes
- **Report only binary-incompatible changes**: No
- **Access modifier filter**: `PROTECTED`
- **Old archives**:
  - ![commons-fileupload 1.5](https://img.shields.io/badge/commons_fileupload-1.5-blue "commons-fileupload 1.5")
- **New archives**:
  - ![commons-fileupload 1.6.0](https://img.shields.io/badge/commons_fileupload-1.6.0-blue "commons-fileupload 1.6.0")
- **Evaluate annotations**: Yes
- **Include synthetic classes and class members**: No
- **Include specific elements**: No
- **Exclude specific elements**: No
- **Ignore all missing classes**: No
- **Ignore specific missing classes**: No
- **Treat changes as errors**:
  - Any changes: No
  - Binary incompatible changes: No
  - Source incompatible changes: No
  - Incompatible changes caused by excluded classes: Yes
  - Semantically incompatible changes: No
  - Semantically incompatible changes, including development versions: No
- **Classpath mode**: `ONE_COMMON_CLASSPATH`
- **Old classpath**:
```

```
- **New classpath**:
```

```

</details>


## Results

| Status   | Type                                                | Serialization       | Compatibility Changes |
|----------|-----------------------------------------------------|---------------------|-----------------------|
| Modified | [org.apache.commons.fileupload.FileUploadBase]      | ![Not serializable] | ![Method added to public class] ![Method no longer throws checked exception] |
| Modified | [org.apache.commons.fileupload.FileUploadBase$FileUploadIOException] | ![Compatible] | ![No changes] |
| Modified | [org.apache.commons.fileupload.FileUploadBase$IOFileUploadException] | ![Compatible] | ![No changes] |
| Modified | [org.apache.commons.fileupload.FileUploadException] | ![Compatible]       | ![No changes]         |
| Modified | [org.apache.commons.fileupload.MultipartStream]     | ![Not serializable] | ![Annotation deprecated added] ![Method added to public class] |
| Modified | [org.apache.commons.fileupload.disk.DiskFileItem]   | ![Not serializable] | ![No changes]         |

<details markdown="1">
<summary>Expand for details.</summary>

___

<a id="user-content-org.apache.commons.fileupload.fileuploadbase"></a>
### `org.apache.commons.fileupload.FileUploadBase`

- [X] Binary-compatible
- [ ] Source-compatible
- [X] Serialization-compatible

| Status   | Modifiers           | Type  | Name             | Extends    | JDK                        | Serialization       | Compatibility Changes |
|----------|---------------------|-------|------------------|------------|----------------------------|---------------------|-----------------------|
| Modified | `public` `abstract` | Class | `FileUploadBase` | [`Object`] | ~~JDK 6~~ &rarr; **JDK 8** | ![Not serializable] | ![No changes]         |


#### Methods

| Status   | Modifiers    | Generics | Type         | Method                                           | Annotations | Throws                      | Compatibility Changes |
|----------|--------------|----------|--------------|--------------------------------------------------|-------------|-----------------------------|-----------------------|
| Modified | `protected`  |          | [`FileItem`] | `createItem`([`Map<String, String>`], `boolean`) |             | ~~[`FileUploadException`]~~ | ![Method no longer throws checked exception] |
| Added    | **`public`** |          | **`int`**    | **`getPartHeaderSizeMax`**()                     |             |                             | ![Method added to public class] |
| Added    | **`public`** |          | **`void`**   | **`setPartHeaderSizeMax`**(`int`)                |             |                             | ![Method added to public class] |


#### Fields

| Status | Modifiers                             | Type           | Name                           | Annotations | Compatibility Changes |
|--------|---------------------------------------|----------------|--------------------------------|-------------|-----------------------|
| Added  | **`public`** **`static`** **`final`** | **`int`**      | `DEFAULT_PART_HEADER_SIZE_MAX` |             | ![No changes]         |
| Added  | **`public`** **`static`** **`final`** | **[`String`]** | `MULTIPART_RELATED`            |             | ![No changes]         |

___

<a id="user-content-org.apache.commons.fileupload.fileuploadbase$fileuploadioexception"></a>
### `org.apache.commons.fileupload.FileUploadBase$FileUploadIOException`

- [X] Binary-compatible
- [X] Source-compatible
- [X] Serialization-compatible

| Status   | Modifiers         | Type  | Name                    | Extends         | JDK                        | Serialization | Compatibility Changes |
|----------|-------------------|-------|-------------------------|-----------------|----------------------------|---------------|-----------------------|
| Modified | `static` `public` | Class | `FileUploadIOException` | [`IOException`] | ~~JDK 6~~ &rarr; **JDK 8** | ![Compatible] | ![No changes]         |


#### Methods

| Status  | Modifiers    | Generics | Type              | Method           | Annotations | Throws | Compatibility Changes |
|---------|--------------|----------|-------------------|------------------|-------------|--------|-----------------------|
| Removed | ~~`public`~~ |          | ~~[`Throwable`]~~ | ~~`getCause`~~() |             |        | ![No changes]         |

___

<a id="user-content-org.apache.commons.fileupload.fileuploadbase$iofileuploadexception"></a>
### `org.apache.commons.fileupload.FileUploadBase$IOFileUploadException`

- [X] Binary-compatible
- [X] Source-compatible
- [X] Serialization-compatible

| Status   | Modifiers         | Type  | Name                    | Extends                 | JDK                        | Serialization | Compatibility Changes |
|----------|-------------------|-------|-------------------------|-------------------------|----------------------------|---------------|-----------------------|
| Modified | `static` `public` | Class | `IOFileUploadException` | [`FileUploadException`] | ~~JDK 6~~ &rarr; **JDK 8** | ![Compatible] | ![No changes]         |


#### Methods

| Status  | Modifiers    | Generics | Type              | Method           | Annotations | Throws | Compatibility Changes |
|---------|--------------|----------|-------------------|------------------|-------------|--------|-----------------------|
| Removed | ~~`public`~~ |          | ~~[`Throwable`]~~ | ~~`getCause`~~() |             |        | ![No changes]         |

___

<a id="user-content-org.apache.commons.fileupload.fileuploadexception"></a>
### `org.apache.commons.fileupload.FileUploadException`

- [X] Binary-compatible
- [X] Source-compatible
- [X] Serialization-compatible

| Status   | Modifiers | Type  | Name                  | Extends       | JDK                        | Serialization | Compatibility Changes |
|----------|-----------|-------|-----------------------|---------------|----------------------------|---------------|-----------------------|
| Modified | `public`  | Class | `FileUploadException` | [`Exception`] | ~~JDK 6~~ &rarr; **JDK 8** | ![Compatible] | ![No changes]         |


#### Methods

| Status  | Modifiers    | Generics | Type              | Method                                 | Annotations | Throws | Compatibility Changes |
|---------|--------------|----------|-------------------|----------------------------------------|-------------|--------|-----------------------|
| Removed | ~~`public`~~ |          | ~~[`Throwable`]~~ | ~~`getCause`~~()                       |             |        | ![No changes]         |
| Removed | ~~`public`~~ |          | ~~`void`~~        | ~~`printStackTrace`~~([`PrintStream`]) |             |        | ![No changes]         |
| Removed | ~~`public`~~ |          | ~~`void`~~        | ~~`printStackTrace`~~([`PrintWriter`]) |             |        | ![No changes]         |

___

<a id="user-content-org.apache.commons.fileupload.multipartstream"></a>
### `org.apache.commons.fileupload.MultipartStream`

- [X] Binary-compatible
- [X] Source-compatible
- [X] Serialization-compatible

| Status   | Modifiers | Type  | Name              | Extends    | JDK                        | Serialization       | Compatibility Changes |
|----------|-----------|-------|-------------------|------------|----------------------------|---------------------|-----------------------|
| Modified | `public`  | Class | `MultipartStream` | [`Object`] | ~~JDK 6~~ &rarr; **JDK 8** | ![Not serializable] | ![No changes]         |


#### Methods

| Status | Modifiers    | Generics | Type       | Method                            | Annotations | Throws | Compatibility Changes |
|--------|--------------|----------|------------|-----------------------------------|-------------|--------|-----------------------|
| Added  | **`public`** |          | **`int`**  | **`getPartHeaderSizeMax`**()      |             |        | ![Method added to public class] |
| Added  | **`public`** |          | **`void`** | **`setPartHeaderSizeMax`**(`int`) |             |        | ![Method added to public class] |


#### Fields

| Status    | Modifiers                 | Type  | Name                   | Annotations        | Compatibility Changes |
|-----------|---------------------------|-------|------------------------|--------------------|-----------------------|
| Unchanged | `public` `static` `final` | `int` | `HEADER_PART_SIZE_MAX` | **[`Deprecated`]** | ![Annotation deprecated added] |

___

<a id="user-content-org.apache.commons.fileupload.disk.diskfileitem"></a>
### `org.apache.commons.fileupload.disk.DiskFileItem`

- [X] Binary-compatible
- [X] Source-compatible
- [X] Serialization-compatible

| Status   | Modifiers | Type  | Name           | Extends    | JDK                        | Serialization       | Compatibility Changes |
|----------|-----------|-------|----------------|------------|----------------------------|---------------------|-----------------------|
| Modified | `public`  | Class | `DiskFileItem` | [`Object`] | ~~JDK 6~~ &rarr; **JDK 8** | ![Not serializable] | ![No changes]         |


#### Methods

| Status   | Modifiers   | Generics | Type   | Method       | Annotations | Throws            | Compatibility Changes |
|----------|-------------|----------|--------|--------------|-------------|-------------------|-----------------------|
| Modified | `protected` |          | `void` | `finalize`() |             | **[`Throwable`]** | ![No changes]         |


</details>


___

*Generated on: 2025-06-05 15:19:00.789+0000*.

[Annotation deprecated added]: https://img.shields.io/badge/Annotation_deprecated_added-orange "Annotation deprecated added"
[Compatible]: https://img.shields.io/badge/Compatible-green "Compatible"
[Method added to public class]: https://img.shields.io/badge/Method_added_to_public_class-yellow "Method added to public class"
[Method no longer throws checked exception]: https://img.shields.io/badge/Method_no_longer_throws_checked_exception-orange "Method no longer throws checked exception"
[No changes]: https://img.shields.io/badge/No_changes-green "No changes"
[Not serializable]: https://img.shields.io/badge/Not_serializable-green "Not serializable"
[`Deprecated`]: # "java.lang.Deprecated"
[`Exception`]: # "java.lang.Exception"
[`FileItem`]: # "org.apache.commons.fileupload.FileItem"
[`FileUploadException`]: # "org.apache.commons.fileupload.FileUploadException"
[`IOException`]: # "java.io.IOException"
[`Map<String, String>`]: # "java.util.Map<java.lang.String, java.lang.String>"
[`Object`]: # "java.lang.Object"
[`PrintStream`]: # "java.io.PrintStream"
[`PrintWriter`]: # "java.io.PrintWriter"
[`String`]: # "java.lang.String"
[`Throwable`]: # "java.lang.Throwable"
[org.apache.commons.fileupload.FileUploadBase]: #user-content-org.apache.commons.fileupload.fileuploadbase
[org.apache.commons.fileupload.FileUploadBase$FileUploadIOException]: #user-content-org.apache.commons.fileupload.fileuploadbase$fileuploadioexception
[org.apache.commons.fileupload.FileUploadBase$IOFileUploadException]: #user-content-org.apache.commons.fileupload.fileuploadbase$iofileuploadexception
[org.apache.commons.fileupload.FileUploadException]: #user-content-org.apache.commons.fileupload.fileuploadexception
[org.apache.commons.fileupload.MultipartStream]: #user-content-org.apache.commons.fileupload.multipartstream
[org.apache.commons.fileupload.disk.DiskFileItem]: #user-content-org.apache.commons.fileupload.disk.diskfileitem
