// StayAwake: a menu bar app that keeps the Mac (and its network) awake while it runs.
package main

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa -framework IOKit
#include "tray.h"
*/
import "C"

import (
	_ "embed"
	"runtime"
	"unsafe"
)

//go:embed icons/icon.png
var icon []byte

func init() { runtime.LockOSThread() } // AppKit must run on the main thread

func main() {
	C.trayRun(unsafe.Pointer(&icon[0]), C.int(len(icon)))
}
