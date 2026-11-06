package core

import (
	"encoding/json"
	"strings"
)

// parseFlagFromMap 判断 seku 取流结果是否要求「走解析接口」。
// 站源返回 map 里的 parse / jx 键为真（bool true、数值 1、字符串 "1"）时返回 true。
// 与红蚁TV huoyi-104-source 的 app_parse.go 保持一致。
func parseFlagFromMap(m map[string]interface{}) bool {
	for _, key := range []string{"parse", "jx"} {
		switch v := m[key].(type) {
		case bool:
			if v {
				return true
			}
		case float64:
			if v == 1 {
				return true
			}
		case int:
			if v == 1 {
				return true
			}
		case json.Number:
			if v.String() == "1" {
				return true
			}
		case string:
			if strings.TrimSpace(v) == "1" {
				return true
			}
		}
	}
	return false
}
