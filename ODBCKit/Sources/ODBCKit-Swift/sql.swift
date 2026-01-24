import Darwin

#if canImport(iODBC)
import iODBC
#elseif canImport(ODBC)
import ODBC
#endif

// this implementation assumed that the version is 3 or above and implements the
// older definitions only as fallbacks

// sql.h

/*
 *  Set default specification to ODBC 3.51
 */
public let ODBCVER                                : Int32      = 0x0351

/*
 *  Useful Constants
 */
public let SQL_MAX_MESSAGE_LENGTH                 : Int     = 512

/*
 *  Handle types
 */
public let SQL_HANDLE_ENV                         : SQLSMALLINT = 1
public let SQL_HANDLE_DBC                         : SQLSMALLINT = 2
public let SQL_HANDLE_STMT                        : SQLSMALLINT = 3
public let SQL_HANDLE_DESC                        : SQLSMALLINT = 4

/*
 *  Function return codes
 */
public let SQL_SUCCESS                            : SQLSMALLINT = 0
public let SQL_SUCCESS_WITH_INFO                  : SQLSMALLINT = 1
public let SQL_STILL_EXECUTING                    : SQLSMALLINT = 2
public let SQL_ERROR                             : SQLSMALLINT = -1
public let SQL_INVALID_HANDLE                     : SQLSMALLINT = -2
public let SQL_NEED_DATA                          : SQLSMALLINT = 99
public let SQL_NO_DATA                           : SQLSMALLINT = 100

/*
 *  Test for SQL_SUCCESS or SQL_SUCCESS_WITH_INFO
 */
@inlinable
public func SQL_SUCCEEDED(_ rc: SQLRETURN) -> Bool {
    return (rc & ~1) == 0
}

/*
 *  Special length values
 */
public let SQL_NULL_DATA                         : SQLSMALLINT = -1
public let SQL_DATA_AT_EXEC                      : SQLSMALLINT = -2


/*
 *  Flags for null-terminated strings
 */
public let SQL_NTS                               : SQLSMALLINT = -3
public let SQL_NTSL                              : SQLSMALLINT = -3


/*
 *  Standard SQL datatypes, using ANSI type numbering
 */
public let SQL_UNKNOWN_TYPE                      : SQLSMALLINT = 0
public let SQL_CHAR                              : SQLSMALLINT = 1
public let SQL_NUMERIC                           : SQLSMALLINT = 2
public let SQL_DECIMAL                           : SQLSMALLINT = 3
public let SQL_INTEGER                           : SQLSMALLINT = 4
public let SQL_SMALLINT                          : SQLSMALLINT = 5
public let SQL_FLOAT                             : SQLSMALLINT = 6
public let SQL_REAL                              : SQLSMALLINT = 7
public let SQL_DOUBLE                            : SQLSMALLINT = 8
public let SQL_DATETIME                          : SQLSMALLINT = 9
public let SQL_VARCHAR                           : SQLSMALLINT = 12

/*
 *  SQLGetTypeInfo request for all data types
 */
public let SQL_ALL_TYPES                         : SQLSMALLINT = 0

/*
 *  Statement attribute values for date/time data types
 */
public let SQL_TYPE_DATE                         : SQLSMALLINT = 91
public let SQL_TYPE_TIME                         : SQLSMALLINT = 92
public let SQL_TYPE_TIMESTAMP                    : SQLSMALLINT = 93

/*
 *  Date/Time length constants
 */
public let SQL_DATE_LEN                          : SQLSMALLINT = 10
public let SQL_TIME_LEN                          : SQLSMALLINT = 8    /* add P+1 if prec >0 */
public let SQL_TIMESTAMP_LEN                     : SQLSMALLINT = 19    /* add P+1 if prec >0 */

/*
 *  NULL status constants
 */
public let SQL_NO_NULLS                          : SQLSMALLINT = 0
public let SQL_NULLABLE                          : SQLSMALLINT = 1
public let SQL_NULLABLE_UNKNOWN                  : SQLSMALLINT = 2


/*
 *  NULL Handles
 */
public let SQL_NULL_HENV                         : SQLSMALLINT = 0
public let SQL_NULL_HDBC                         : SQLSMALLINT = 0
public let SQL_NULL_HSTMT                        : SQLSMALLINT = 0
public let SQL_NULL_HDESC                        : SQLSMALLINT = 0


/*
 *  NULL handle for parent argument to SQLAllocHandle when allocating
 *  a SQLHENV
 */
public let SQL_NULL_HANDLE                       : SQLSMALLINT = 0


/*
 *  CLI option values
 */
public let SQL_FALSE                             : SQLSMALLINT = 0
public let SQL_TRUE                              : SQLSMALLINT = 1


/*
 *  Default conversion code for SQLBindCol(), SQLBindParam() and SQLGetData()
 */
public let SQL_DEFAULT                           : SQLSMALLINT = 99


/*
 *  SQLDataSources/SQLFetchScroll - FetchOrientation
 */
public let SQL_FETCH_NEXT                        : SQLSMALLINT = 1
public let SQL_FETCH_FIRST                       : SQLSMALLINT = 2


/*
 *  SQLFetchScroll - FetchOrientation
 */
public let SQL_FETCH_LAST                        : SQLSMALLINT = 3
public let SQL_FETCH_PRIOR                       : SQLSMALLINT = 4
public let SQL_FETCH_ABSOLUTE                    : SQLSMALLINT = 5
public let SQL_FETCH_RELATIVE                    : SQLSMALLINT = 6


/*
 *  SQLFreeStmt
 */
public let SQL_CLOSE                             : SQLSMALLINT = 0
public let SQL_DROP                              : SQLSMALLINT = 1
public let SQL_UNBIND                            : SQLSMALLINT = 2
public let SQL_RESET_PARAMS                      : SQLSMALLINT = 3


/*
 *  SQLGetConnectAttr - connection attributes
 */
public let SQL_ATTR_AUTO_IPD                     : SQLSMALLINT = 10001
public let SQL_ATTR_METADATA_ID                  : SQLSMALLINT = 10014


/*
 *   SQLGetData() code indicating that the application row descriptor
 *   specifies the data type
 */
public let SQL_ARD_TYPE                         : SQLSMALLINT = -99


/*
 *  SQLGetDescField - identifiers of fields in the SQL descriptor
 */
public let SQL_DESC_COUNT                       : SQLSMALLINT = 1001
public let SQL_DESC_TYPE                        : SQLSMALLINT = 1002
public let SQL_DESC_LENGTH                      : SQLSMALLINT = 1003
public let SQL_DESC_OCTET_LENGTH_PTR           : SQLSMALLINT = 1004
public let SQL_DESC_PRECISION                   : SQLSMALLINT = 1005
public let SQL_DESC_SCALE                       : SQLSMALLINT = 1006
public let SQL_DESC_DATETIME_INTERVAL_CODE     : SQLSMALLINT = 1007
public let SQL_DESC_NULLABLE                    : SQLSMALLINT = 1008
public let SQL_DESC_INDICATOR_PTR               : SQLSMALLINT = 1009
public let SQL_DESC_DATA_PTR                    : SQLSMALLINT = 1010
public let SQL_DESC_NAME                        : SQLSMALLINT = 1011
public let SQL_DESC_UNNAMED                     : SQLSMALLINT = 1012
public let SQL_DESC_OCTET_LENGTH                : SQLSMALLINT = 1013
public let SQL_DESC_ALLOC_TYPE                  : SQLSMALLINT = 1099


/*
 *  SQLGetDescField - SQL_DESC_ALLOC_TYPE
 */
public let SQL_DESC_ALLOC_AUTO                  : SQLSMALLINT = 1
public let SQL_DESC_ALLOC_USER                  : SQLSMALLINT = 2


/*
 *  SQLGetDescField - SQL_DESC_DATETIME_INTERVAL_CODE
 */
public let SQL_CODE_DATE                        : SQLSMALLINT = 1
public let SQL_CODE_TIME                        : SQLSMALLINT = 2
public let SQL_CODE_TIMESTAMP                   : SQLSMALLINT = 3


/*
 *  SQLGetDescField - SQL_DESC_UNNAMED
 */
public let SQL_NAMED                            : SQLSMALLINT = 0
public let SQL_UNNAMED                          : SQLSMALLINT = 1


/*
 *  SQLGetDiagField - identifiers of fields in the diagnostics area
 */
public let SQL_DIAG_RETURNCODE                  : SQLSMALLINT = 1
public let SQL_DIAG_NUMBER                      : SQLSMALLINT = 2
public let SQL_DIAG_ROW_COUNT                   : SQLSMALLINT = 3
public let SQL_DIAG_SQLSTATE                    : SQLSMALLINT = 4
public let SQL_DIAG_NATIVE                      : SQLSMALLINT = 5
public let SQL_DIAG_MESSAGE_TEXT                : SQLSMALLINT = 6
public let SQL_DIAG_DYNAMIC_FUNCTION            : SQLSMALLINT = 7
public let SQL_DIAG_CLASS_ORIGIN                : SQLSMALLINT = 8
public let SQL_DIAG_SUBCLASS_ORIGIN             : SQLSMALLINT = 9
public let SQL_DIAG_CONNECTION_NAME             : SQLSMALLINT = 10
public let SQL_DIAG_SERVER_NAME                 : SQLSMALLINT = 11
public let SQL_DIAG_DYNAMIC_FUNCTION_CODE       : SQLSMALLINT = 12


/*
 *  SQLGetDiagField - SQL_DIAG_DYNAMIC_FUNCTION_CODE
 */
public let SQL_DIAG_ALTER_DOMAIN               : SQLSMALLINT = 3
public let SQL_DIAG_ALTER_TABLE                : SQLSMALLINT = 4
public let SQL_DIAG_CALL                       : SQLSMALLINT = 7
public let SQL_DIAG_CREATE_ASSERTION           : SQLSMALLINT = 6
public let SQL_DIAG_CREATE_CHARACTER_SET       : SQLSMALLINT = 8
public let SQL_DIAG_CREATE_COLLATION           : SQLSMALLINT = 10
public let SQL_DIAG_CREATE_DOMAIN              : SQLSMALLINT = 23
public let SQL_DIAG_CREATE_INDEX               : SQLSMALLINT = -1
public let SQL_DIAG_CREATE_SCHEMA              : SQLSMALLINT = 64
public let SQL_DIAG_CREATE_TABLE               : SQLSMALLINT = 77
public let SQL_DIAG_CREATE_TRANSLATION         : SQLSMALLINT = 79
public let SQL_DIAG_CREATE_VIEW                : SQLSMALLINT = 84
public let SQL_DIAG_DELETE_WHERE               : SQLSMALLINT = 19
public let SQL_DIAG_DROP_ASSERTION             : SQLSMALLINT = 24
public let SQL_DIAG_DROP_CHARACTER_SET         : SQLSMALLINT = 25
public let SQL_DIAG_DROP_COLLATION             : SQLSMALLINT = 26
public let SQL_DIAG_DROP_DOMAIN                : SQLSMALLINT = 27
public let SQL_DIAG_DROP_INDEX                 : SQLSMALLINT = -2
public let SQL_DIAG_DROP_SCHEMA                : SQLSMALLINT = 31
public let SQL_DIAG_DROP_TABLE                 : SQLSMALLINT = 32
public let SQL_DIAG_DROP_TRANSLATION           : SQLSMALLINT = 33
public let SQL_DIAG_DROP_VIEW                  : SQLSMALLINT = 36
public let SQL_DIAG_DYNAMIC_DELETE_CURSOR      : SQLSMALLINT = 38
public let SQL_DIAG_DYNAMIC_UPDATE_CURSOR      : SQLSMALLINT = 81
public let SQL_DIAG_GRANT                      : SQLSMALLINT = 48
public let SQL_DIAG_INSERT                     : SQLSMALLINT = 50
public let SQL_DIAG_REVOKE                     : SQLSMALLINT = 59
public let SQL_DIAG_SELECT_CURSOR              : SQLSMALLINT = 85
public let SQL_DIAG_UNKNOWN_STATEMENT         : SQLSMALLINT = 0
public let SQL_DIAG_UPDATE_WHERE               : SQLSMALLINT = 82


/*
 *  SQLGetEnvAttr - environment attribute
 */
public let SQL_ATTR_OUTPUT_NTS                  : SQLSMALLINT = 10001


/*
 *  SQLGetFunctions
 */
public let SQL_API_SQLALLOCCONNECT               : SQLSMALLINT = 1
public let SQL_API_SQLALLOCENV                   : SQLSMALLINT = 2
public let SQL_API_SQLALLOCHANDLE                : SQLSMALLINT = 1001
public let SQL_API_SQLALLOCSTMT                  : SQLSMALLINT = 3
public let SQL_API_SQLBINDCOL                    : SQLSMALLINT = 4
public let SQL_API_SQLBINDPARAM                  : SQLSMALLINT = 1002
public let SQL_API_SQLCANCEL                     : SQLSMALLINT = 5
public let SQL_API_SQLCLOSECURSOR                : SQLSMALLINT = 1003
public let SQL_API_SQLCOLATTRIBUTE               : SQLSMALLINT = 6
public let SQL_API_SQLCOLUMNS                    : SQLSMALLINT = 40
public let SQL_API_SQLCONNECT                    : SQLSMALLINT = 7
public let SQL_API_SQLCOPYDESC                   : SQLSMALLINT = 1004
public let SQL_API_SQLDATASOURCES                : SQLSMALLINT = 57
public let SQL_API_SQLDESCRIBECOL                : SQLSMALLINT = 8
public let SQL_API_SQLDISCONNECT                 : SQLSMALLINT = 9
public let SQL_API_SQLENDTRAN                    : SQLSMALLINT = 1005
public let SQL_API_SQLERROR                      : SQLSMALLINT = 10
public let SQL_API_SQLEXECDIRECT                 : SQLSMALLINT = 11
public let SQL_API_SQLEXECUTE                    : SQLSMALLINT = 12
public let SQL_API_SQLFETCH                      : SQLSMALLINT = 13
public let SQL_API_SQLFETCHSCROLL                : SQLSMALLINT = 1021
public let SQL_API_SQLFREECONNECT                : SQLSMALLINT = 14
public let SQL_API_SQLFREEENV                    : SQLSMALLINT = 15
public let SQL_API_SQLFREEHANDLE                 : SQLSMALLINT = 1006
public let SQL_API_SQLFREESTMT                   : SQLSMALLINT = 16
public let SQL_API_SQLGETCONNECTATTR             : SQLSMALLINT = 1007
public let SQL_API_SQLGETCONNECTOPTION           : SQLSMALLINT = 42
public let SQL_API_SQLGETCURSORNAME              : SQLSMALLINT = 17
public let SQL_API_SQLGETDATA                    : SQLSMALLINT = 43
public let SQL_API_SQLGETDESCFIELD               : SQLSMALLINT = 1008
public let SQL_API_SQLGETDESCREC                 : SQLSMALLINT = 1009
public let SQL_API_SQLGETDIAGFIELD               : SQLSMALLINT = 1010
public let SQL_API_SQLGETDIAGREC                 : SQLSMALLINT = 1011
public let SQL_API_SQLGETENVATTR                 : SQLSMALLINT = 1012
public let SQL_API_SQLGETFUNCTIONS               : SQLSMALLINT = 44
public let SQL_API_SQLGETINFO                    : SQLSMALLINT = 45
public let SQL_API_SQLGETSTMTATTR                : SQLSMALLINT = 1014
public let SQL_API_SQLGETSTMTOPTION              : SQLSMALLINT = 46
public let SQL_API_SQLGETTYPEINFO                : SQLSMALLINT = 47
public let SQL_API_SQLNUMRESULTCOLS              : SQLSMALLINT = 18
public let SQL_API_SQLPARAMDATA                  : SQLSMALLINT = 48
public let SQL_API_SQLPREPARE                    : SQLSMALLINT = 19
public let SQL_API_SQLPUTDATA                    : SQLSMALLINT = 49
public let SQL_API_SQLROWCOUNT                   : SQLSMALLINT = 20
public let SQL_API_SQLSETCONNECTATTR             : SQLSMALLINT = 1016
public let SQL_API_SQLSETCONNECTOPTION           : SQLSMALLINT = 50
public let SQL_API_SQLSETCURSORNAME              : SQLSMALLINT = 21
public let SQL_API_SQLSETDESCFIELD               : SQLSMALLINT = 1017
public let SQL_API_SQLSETDESCREC                 : SQLSMALLINT = 1018
public let SQL_API_SQLSETENVATTR                 : SQLSMALLINT = 1019
public let SQL_API_SQLSETPARAM                   : SQLSMALLINT = 22
public let SQL_API_SQLSETSTMTATTR                : SQLSMALLINT = 1020
public let SQL_API_SQLSETSTMTOPTION              : SQLSMALLINT = 51
public let SQL_API_SQLSPECIALCOLUMNS             : SQLSMALLINT = 52
public let SQL_API_SQLSTATISTICS                 : SQLSMALLINT = 53
public let SQL_API_SQLTABLES                     : SQLSMALLINT = 54
public let SQL_API_SQLTRANSACT                   : SQLSMALLINT = 23


/*
 *  SQLGetInfo
 */
public let SQL_MAX_DRIVER_CONNECTIONS            : SQLSMALLINT = 0
public let SQL_MAXIMUM_DRIVER_CONNECTIONS        : SQLSMALLINT = SQL_MAX_DRIVER_CONNECTIONS
public let SQL_MAX_CONCURRENT_ACTIVITIES         : SQLSMALLINT = 1
public let SQL_MAXIMUM_CONCURRENT_ACTIVITIES     : SQLSMALLINT = SQL_MAX_CONCURRENT_ACTIVITIES
public let SQL_DATA_SOURCE_NAME                  : SQLSMALLINT = 2
public let SQL_FETCH_DIRECTION                   : SQLSMALLINT = 8
public let SQL_SERVER_NAME                       : SQLSMALLINT = 13
public let SQL_SEARCH_PATTERN_ESCAPE             : SQLSMALLINT = 14
public let SQL_DBMS_NAME                         : SQLSMALLINT = 17
public let SQL_DBMS_VER                          : SQLSMALLINT = 18
public let SQL_ACCESSIBLE_TABLES                 : SQLSMALLINT = 19
public let SQL_ACCESSIBLE_PROCEDURES             : SQLSMALLINT = 20
public let SQL_CURSOR_COMMIT_BEHAVIOR            : SQLSMALLINT = 23
public let SQL_DATA_SOURCE_READ_ONLY             : SQLSMALLINT = 25
public let SQL_DEFAULT_TXN_ISOLATION              : SQLSMALLINT = 26
public let SQL_IDENTIFIER_CASE                   : SQLSMALLINT = 28
public let SQL_IDENTIFIER_QUOTE_CHAR              : SQLSMALLINT = 29
public let SQL_MAX_COLUMN_NAME_LEN               : SQLSMALLINT = 30
public let SQL_MAXIMUM_COLUMN_NAME_LENGTH        : SQLSMALLINT = SQL_MAX_COLUMN_NAME_LEN
public let SQL_MAX_CURSOR_NAME_LEN               : SQLSMALLINT = 31
public let SQL_MAXIMUM_CURSOR_NAME_LENGTH        : SQLSMALLINT = SQL_MAX_CURSOR_NAME_LEN
public let SQL_MAX_SCHEMA_NAME_LEN               : SQLSMALLINT = 32
public let SQL_MAXIMUM_SCHEMA_NAME_LENGTH        : SQLSMALLINT = SQL_MAX_SCHEMA_NAME_LEN
public let SQL_MAX_CATALOG_NAME_LEN              : SQLSMALLINT = 34
public let SQL_MAXIMUM_CATALOG_NAME_LENGTH       : SQLSMALLINT = SQL_MAX_CATALOG_NAME_LEN
public let SQL_MAX_TABLE_NAME_LEN                : SQLSMALLINT = 35
public let SQL_SCROLL_CONCURRENCY                : SQLSMALLINT = 43
public let SQL_TXN_CAPABLE                       : SQLSMALLINT = 46
public let SQL_TRANSACTION_CAPABLE               : SQLSMALLINT = SQL_TXN_CAPABLE
public let SQL_USER_NAME                         : SQLSMALLINT = 47
public let SQL_TXN_ISOLATION_OPTION               : SQLSMALLINT = 72
public let SQL_TRANSACTION_ISOLATION_OPTION      : SQLSMALLINT = SQL_TXN_ISOLATION_OPTION
public let SQL_INTEGRITY                         : SQLSMALLINT = 73
public let SQL_GETDATA_EXTENSIONS                : SQLSMALLINT = 81
public let SQL_NULL_COLLATION                    : SQLSMALLINT = 85
public let SQL_ALTER_TABLE                       : SQLSMALLINT = 86
public let SQL_ORDER_BY_COLUMNS_IN_SELECT        : SQLSMALLINT = 90
public let SQL_SPECIAL_CHARACTERS                : SQLSMALLINT = 94
public let SQL_MAX_COLUMNS_IN_GROUP_BY           : SQLSMALLINT = 97
public let SQL_MAXIMUM_COLUMNS_IN_GROUP_BY       : SQLSMALLINT = SQL_MAX_COLUMNS_IN_GROUP_BY
public let SQL_MAX_COLUMNS_IN_INDEX               : SQLSMALLINT = 98
public let SQL_MAXIMUM_COLUMNS_IN_INDEX           : SQLSMALLINT = SQL_MAX_COLUMNS_IN_INDEX
public let SQL_MAX_COLUMNS_IN_ORDER_BY            : SQLSMALLINT = 99
public let SQL_MAXIMUM_COLUMNS_IN_ORDER_BY        : SQLSMALLINT = SQL_MAX_COLUMNS_IN_ORDER_BY
public let SQL_MAX_COLUMNS_IN_SELECT              : SQLSMALLINT = 100
public let SQL_MAXIMUM_COLUMNS_IN_SELECT          : SQLSMALLINT = SQL_MAX_COLUMNS_IN_SELECT
public let SQL_MAX_COLUMNS_IN_TABLE               : SQLSMALLINT = 101
public let SQL_MAX_INDEX_SIZE                     : SQLSMALLINT = 102
public let SQL_MAXIMUM_INDEX_SIZE                 : SQLSMALLINT = SQL_MAX_INDEX_SIZE
public let SQL_MAX_ROW_SIZE                       : SQLSMALLINT = 104
public let SQL_MAXIMUM_ROW_SIZE                   : SQLSMALLINT = SQL_MAX_ROW_SIZE
public let SQL_MAX_STATEMENT_LEN                  : SQLSMALLINT = 105
public let SQL_MAXIMUM_STATEMENT_LENGTH           : SQLSMALLINT = SQL_MAX_STATEMENT_LEN
public let SQL_MAX_TABLES_IN_SELECT               : SQLSMALLINT = 106
public let SQL_MAXIMUM_TABLES_IN_SELECT           : SQLSMALLINT = SQL_MAX_TABLES_IN_SELECT
public let SQL_MAX_USER_NAME_LEN                  : SQLSMALLINT = 107
public let SQL_MAXIMUM_USER_NAME_LENGTH           : SQLSMALLINT = SQL_MAX_USER_NAME_LEN
public let SQL_OJ_CAPABILITIES                   : SQLSMALLINT = 115
public let SQL_OUTER_JOIN_CAPABILITIES           : SQLSMALLINT = SQL_OJ_CAPABILITIES

public let SQL_XOPEN_CLI_YEAR                    : SQLUINTEGER = 10000
public let SQL_CURSOR_SENSITIVITY                : SQLUINTEGER = 10001
public let SQL_DESCRIBE_PARAMETER                : SQLUINTEGER = 10002
public let SQL_CATALOG_NAME                      : SQLUINTEGER = 10003
public let SQL_COLLATION_SEQ                     : SQLUINTEGER = 10004
public let SQL_MAX_IDENTIFIER_LEN                : SQLUINTEGER = 10005
public let SQL_MAXIMUM_IDENTIFIER_LENGTH         : SQLUINTEGER = SQL_MAX_IDENTIFIER_LEN


/*
 *  SQLGetInfo - SQL_ALTER_TABLE
 */
public let SQL_AT_ADD_COLUMN                     : SQLUINTEGER = 0x00000001
public let SQL_AT_DROP_COLUMN                    : SQLUINTEGER = 0x00000002
public let SQL_AT_ADD_CONSTRAINT                 : SQLUINTEGER = 0x00000008

/*
 *  SQLGetInfo - SQL_ASYNC_MODE
 */
public let SQL_AM_NONE                           : SQLSMALLINT = 0
public let SQL_AM_CONNECTION                     : SQLSMALLINT = 1
public let SQL_AM_STATEMENT                      : SQLSMALLINT = 2


/*
 *  SQLGetInfo - SQL_CURSOR_COMMIT_BEHAVIOR
 */
public let SQL_CB_DELETE                         : SQLSMALLINT = 0
public let SQL_CB_CLOSE                          : SQLSMALLINT = 1
public let SQL_CB_PRESERVE                       : SQLSMALLINT = 2


/*
 *  SQLGetInfo - SQL_FETCH_DIRECTION
 */
public let SQL_FD_FETCH_NEXT                     : SQLUINTEGER = 0x00000001
public let SQL_FD_FETCH_FIRST                    : SQLUINTEGER = 0x00000002
public let SQL_FD_FETCH_LAST                     : SQLUINTEGER = 0x00000004
public let SQL_FD_FETCH_PRIOR                    : SQLUINTEGER = 0x00000008
public let SQL_FD_FETCH_ABSOLUTE                 : SQLUINTEGER = 0x00000010
public let SQL_FD_FETCH_RELATIVE                 : SQLUINTEGER = 0x00000020


/*
 *  SQLGetInfo - SQL_GETDATA_EXTENSIONS
 */
public let SQL_GD_ANY_COLUMN                     : SQLUINTEGER = 0x00000001
public let SQL_GD_ANY_ORDER                      : SQLUINTEGER = 0x00000002


/*
 *  SQLGetInfo - SQL_IDENTIFIER_CASE
 */
public let SQL_IC_UPPER                         : SQLSMALLINT = 1
public let SQL_IC_LOWER                         : SQLSMALLINT = 2
public let SQL_IC_SENSITIVE                     : SQLSMALLINT = 3
public let SQL_IC_MIXED                         : SQLSMALLINT = 4


/*
 *  SQLGetInfo - SQL_NULL_COLLATION
 */
public let SQL_NC_HIGH                          : SQLSMALLINT = 0
public let SQL_NC_LOW                           : SQLSMALLINT = 1


/*
 *  SQLGetInfo - SQL_OJ_CAPABILITIES
 */
public let SQL_OJ_LEFT                          : SQLUINTEGER = 0x00000001
public let SQL_OJ_RIGHT                         : SQLUINTEGER = 0x00000002
public let SQL_OJ_FULL                          : SQLUINTEGER = 0x00000004
public let SQL_OJ_NESTED                        : SQLUINTEGER = 0x00000008
public let SQL_OJ_NOT_ORDERED                   : SQLUINTEGER = 0x00000010
public let SQL_OJ_INNER                         : SQLUINTEGER = 0x00000020
public let SQL_OJ_ALL_COMPARISON_OPS           : SQLUINTEGER = 0x00000040


/*
 *  SQLGetInfo - SQL_SCROLL_CONCURRENCY
 */
public let SQL_SCCO_READ_ONLY                   : SQLUINTEGER = 0x00000001
public let SQL_SCCO_LOCK                        : SQLUINTEGER = 0x00000002
public let SQL_SCCO_OPT_ROWVER                  : SQLUINTEGER = 0x00000004
public let SQL_SCCO_OPT_VALUES                  : SQLUINTEGER = 0x00000008


/*
 *  SQLGetInfo - SQL_TXN_CAPABLE
 */
public let SQL_TC_NONE                          : SQLSMALLINT = 0
public let SQL_TC_DML                           : SQLSMALLINT = 1
public let SQL_TC_ALL                           : SQLSMALLINT = 2
public let SQL_TC_DDL_COMMIT                    : SQLSMALLINT = 3
public let SQL_TC_DDL_IGNORE                    : SQLSMALLINT = 4


/*
 *  SQLGetInfo - SQL_TXN_ISOLATION_OPTION
 */
public let SQL_TXN_READ_UNCOMMITTED            : SQLUINTEGER = 0x00000001
public let SQL_TRANSACTION_READ_UNCOMMITTED    : SQLUINTEGER = SQL_TXN_READ_UNCOMMITTED
public let SQL_TXN_READ_COMMITTED              : SQLUINTEGER = 0x00000002
public let SQL_TRANSACTION_READ_COMMITTED      : SQLUINTEGER = SQL_TXN_READ_COMMITTED
public let SQL_TXN_REPEATABLE_READ             : SQLUINTEGER = 0x00000004
public let SQL_TRANSACTION_REPEATABLE_READ     : SQLUINTEGER = SQL_TXN_REPEATABLE_READ
public let SQL_TXN_SERIALIZABLE                : SQLUINTEGER = 0x00000008
public let SQL_TRANSACTION_SERIALIZABLE        : SQLUINTEGER = SQL_TXN_SERIALIZABLE


/*
 *  SQLGetStmtAttr - statement attributes
 */
public let SQL_ATTR_APP_ROW_DESC                : SQLSMALLINT = 10010
public let SQL_ATTR_APP_PARAM_DESC              : SQLSMALLINT = 10011
public let SQL_ATTR_IMP_ROW_DESC                : SQLSMALLINT = 10012
public let SQL_ATTR_IMP_PARAM_DESC              : SQLSMALLINT = 10013
public let SQL_ATTR_CURSOR_SCROLLABLE           : SQLSMALLINT = -1
public let SQL_ATTR_CURSOR_SENSITIVITY          : SQLSMALLINT = -2


/*
 *  SQLGetStmtAttr - SQL_ATTR_CURSOR_SCROLLABLE
 */
public let SQL_NONSCROLLABLE                    : SQLSMALLINT = 0
public let SQL_SCROLLABLE                      : SQLSMALLINT = 1


/*
 *  SQLGetStmtAttr - SQL_ATTR_CURSOR_SENSITIVITY
 */
public let SQL_UNSPECIFIED                      : SQLSMALLINT = 0
public let SQL_INSENSITIVE                     : SQLSMALLINT = 1
public let SQL_SENSITIVE                       : SQLSMALLINT = 2


/*
 *  SQLGetTypeInfo - SEARCHABLE
 */
public let SQL_PRED_NONE                       : SQLSMALLINT = 0
public let SQL_PRED_CHAR                       : SQLSMALLINT = 1
public let SQL_PRED_BASIC                      : SQLSMALLINT = 2


/*
 *  SQLSpecialColumns - Column scopes
 */
public let SQL_SCOPE_CURROW                    : SQLSMALLINT = 0
public let SQL_SCOPE_TRANSACTION               : SQLSMALLINT = 1
public let SQL_SCOPE_SESSION                   : SQLSMALLINT = 2


/*
 *  SQLSpecialColumns - PSEUDO_COLUMN
 */
public let SQL_PC_UNKNOWN                      : SQLSMALLINT = 0
public let SQL_PC_NON_PSEUDO                   : SQLSMALLINT = 1
public let SQL_PC_PSEUDO                       : SQLSMALLINT = 2


/*
 *  SQLSpecialColumns - IdentifierType
 */
public let SQL_ROW_IDENTIFIER                  : SQLSMALLINT = 1


/*
 *  SQLStatistics - fUnique
 */
public let SQL_INDEX_UNIQUE                    : SQLSMALLINT = 0
public let SQL_INDEX_ALL                       : SQLSMALLINT = 1


/*
 *  SQLStatistics - TYPE
 */
public let SQL_INDEX_CLUSTERED                 : SQLSMALLINT = 1
public let SQL_INDEX_HASHED                    : SQLSMALLINT = 2
public let SQL_INDEX_OTHER                     : SQLSMALLINT = 3


/*
 *  SQLTransact/SQLEndTran
 */
public let SQL_COMMIT                         : SQLSMALLINT = 0
public let SQL_ROLLBACK                       : SQLSMALLINT = 1


// --------------- Generated ---------------------------------------------------


// Enums for Known Values
enum SQLFetchDirection: Int32 {
    case next = 1
    case first = 2
    case last = 3
    case prior = 4
    case absolute = 5
    case relative = 6
}

enum SQLHandleType: Int16 {
    case env = 1
    case dbc = 2
    case stmt = 3
    case desc = 4
}

enum SQLAttrType: Int32 {
    case cursorScrollable = -1
    case cursorSensitivity = -2
}

// Example Usage of Macros in Swift
enum SQLDataType: Int16 {
    case unknownType = 0
    case char = 1
    case varchar = 12
    case longVarChar = 20
}

/*

@_silgen_name("SQLConnect") // Use iODBC's SQLConnect
func SQLConnect(
    _ connectionHandle: SQLHDBC?,
    _ serverName: UnsafePointer<UInt8>?,
    _ nameLength1: SQLSMALLINT,
    _ userName: UnsafePointer<UInt8>?,
    _ nameLength2: SQLSMALLINT,
    _ authentication: UnsafePointer<UInt8>?,
    _ nameLength3: SQLSMALLINT
) -> SQLSMALLINT

@_silgen_name("SQLGetData")
public func SQLGetData(
    _ StatementHandle: SQLHSTMT,                  // Input: Statement handle
    _ ColumnNumber: SQLUSMALLINT,                 // Input: Column to retrieve (1-based index)
    _ TargetType: SQLSMALLINT,                    // Input: C data type to convert to
    _ TargetValuePtr: SQLPOINTER,                 // Output: Buffer for column data
    _ BufferLength: SQLINTEGER,                   // Input: Length of the buffer
    _ StrLenOrInd: UnsafeMutablePointer<SQLINTEGER>? // Output: Length of data returned (or indicator of NULL)
) -> SQLRETURN

*/

