## Benign root/domain redirect, homepage, and general benign site traffic

- 2, 10, 11, 14, 42, 55, 68, 73, 74, 75, 76, 77, 79, 91, 94, 100
- 119, 120, 133, 148, 199, 207, 208, 209, 210, 211, 212, 215, 216, 217, 218, 220, 221, 222
- 223, 225, 227, 228, 229, 230, 231, 233, 234, 239, 242, 244, 245, 246, 249, 251, 253, 254
- 257, 259, 260, 299, 303, 327, 432, 461, 465, 473, 476, 486

These belong together because they are root/domain redirect checks, homepage requests, and other low-risk site traffic.

## Automated root/path probing and HTTP method enumeration

- 1, 3, 28, 31, 39, 80, 90, 97, 104, 146, 192, 195, 213, 232, 236, 240
- 250, 271, 274, 279, 297, 305, 306, 308, 407, 424, 438, 458, 490

These share automated root/path probing or HTTP method enumeration against web roots.

## Distributed/malformed scanning and multipart exploit probing

- 60, 92, 98, 142, 202, 226, 382, 406, 408, 426, 436

These are distributed, malformed, or multipart-based scanning/exploit probes rather than normal browsing.

## robots.txt, sitemap, llms.txt, and SEO discovery crawling

- 6, 20, 50, 51, 59, 67, 107, 116, 122, 126, 127, 138, 145, 182, 200, 201, 243
- 256, 284, 296, 318, 320, 372, 410, 425, 437, 454, 459, 475, 477, 478, 493, 495

These IDs involve robots.txt, sitemap.xml, ads.txt, llms.txt, .well-known, or similar SEO/discovery crawling.

## Named crawler/bot traffic

- 17, 44, 46, 65, 66, 78, 81, 106, 123, 128, 129, 130, 132, 141
- 214, 247, 261, 280, 317, 405, 423, 435, 439, 444, 451

These are requests from named crawlers, bots, or monitoring agents rather than targeted vulnerability probes.

## Favicon, static asset, and service-worker requests

- 24, 34, 57, 70, 89, 96, 237, 277, 281, 390, 428, 434

These center on favicon fetches, JavaScript/static asset retrieval, or service-worker requests.

## WordPress endpoint probing and exploitation

- 4, 18, 25, 32, 48, 49, 52, 111, 125, 131, 136, 144, 176, 193, 194, 219, 224, 238
- 241, 248, 255, 273, 304, 309, 330, 385, 398, 415, 443, 445, 449, 452, 453, 455, 456

These target WordPress-specific endpoints such as REST API, login, XML-RPC, plugins, themes, and related files.

## PHP framework debug/config probing

- 58, 64, 118, 154, 155, 316, 326, 341, 355, 433

These probe PHP framework debug, profiler, source, or runtime config endpoints such as Laravel, Symfony, Livewire, and Yii.

## Spring/JVM/other framework debug and runtime config probing

- 164, 165, 169, 171, 190, 191, 291, 311, 339, 400

These are framework debug, actuator, runtime config, health, or console endpoint probes.

## CI/CD, container, IaC, and orchestration config probing

- 41, 72, 87, 160, 161, 183, 289, 354, 360, 371, 379, 391, 409, 474, 491

These probe build, deployment, container, infrastructure-as-code, or orchestration configuration files/endpoints.

## AI/agent config and MCP endpoint probing

- 170, 174, 177, 178, 179, 180, 186, 189, 295, 313, 388, 440

These target AI assistant, coding agent, or MCP-related configuration files and endpoints.

## VCS metadata exposure probing

- 30, 71, 157, 300, 314, 335, 358, 380, 463

These involve Git, SVN, or other version-control metadata exposure reconnaissance.

## Environment/.env file probing

- 27, 38, 69, 85, 115, 140, 159, 173, 269, 278, 283, 290, 301, 302, 319, 325
- 338, 349, 350, 356, 367, 370, 377, 414, 457, 462, 464, 472, 482, 488, 494, 497

These all seek environment-style configuration files such as .env, env.js, or .env backups.

## Cloud credentials, private keys, and secret files

- 21, 22, 23, 37, 102, 124, 151, 152, 153, 156, 158, 162, 163, 166, 167, 168, 184, 185, 187, 188
- 270, 272, 292, 293, 294, 345, 348, 365, 366, 376, 378, 389, 467, 470, 483, 485, 487, 489, 492

These target cloud provider credentials, service account keys, private keys, and other high-value secret files.

## Generic sensitive config/secret/source file probing

- 5, 9, 88, 143, 181, 198, 268, 276, 285, 322, 323, 331, 333, 334, 346, 351, 352, 357, 359, 368
- 387, 399, 402, 403, 404, 413, 416, 417, 418, 419, 420, 421, 430, 442, 447, 450, 460, 466, 468, 469
- 471, 479, 480, 484

These are broad probes for sensitive application configuration, credential, source, or secret files.

## Log/backup/source file probing

- 47, 298, 321, 363, 369, 393, 411, 498

These focus on log files, backups, database dumps, or similar exposed files.

## SSRF/LFI/path traversal and cloud metadata credential probing

- 29, 35, 40, 53, 103, 172, 175, 286, 288, 315, 347, 353, 361, 364, 381, 383, 384, 386, 392, 394, 427, 441

These involve SSRF, LFI, path traversal, or cloud metadata access intended to read files or steal credentials.

## Router/IoT/embedded device exploit probing

- 8, 15, 16, 56, 108, 149, 150, 205, 263, 267, 282, 310, 332

These target routers, IoT devices, DVRs, cameras, or embedded web interfaces with device-specific exploit paths.

## Enterprise appliance/security gateway/VPN probing

- 45, 54, 61, 110, 117, 197, 324, 429, 431

These probe enterprise appliances, security gateways, VPN portals, or remote-access infrastructure.

## Apache Struts/Java framework exploit probing

- 63, 114, 139, 373, 374, 375

These are Java-oriented exploit or reconnaissance probes against Struts, Axis2, Solr, or similar components.

## Exchange/Atlassian/CMS-specific enterprise exploit probing

- 62, 99, 137, 203, 235, 264, 287, 401

These target Microsoft Exchange, Atlassian services, or related enterprise collaboration platforms.

## CMS-specific probing and CMS scanner traffic

- 7, 19, 82, 84, 93, 95, 101, 112, 252, 262, 329

These are CMS-focused probes for template editors, CMS checkers, or platform-specific files such as Joomla, PbootCMS, and Archivarix.

## Non-WordPress login/auth endpoint probing

- 13, 33, 328, 446

These involve login, prelogin, authentication, or generic login/path enumeration against non-WordPress services.

## Host header, virtual host, and HTTP validation probing

- 0, 12, 121, 206, 307, 396

These involve Host header, virtual host, HTTP validation, or header-based reconnaissance behavior.

## Directory brute-force and generic path enumeration

- 26, 43, 83, 86, 105, 113, 275, 312, 336, 337, 395, 397, 412, 448, 481

These are directory brute-force, random-path, or generic endpoint enumeration probes.

## Other specific exploit/CVE/web server probing

- 36, 109, 134, 135, 147, 196, 204, 258, 265, 266, 340, 342, 343, 344, 362, 422, 496

These are assorted CVE, RCE, PHP webshell, scanner, or web-server-specific probes that do not fit the broader groups above.
