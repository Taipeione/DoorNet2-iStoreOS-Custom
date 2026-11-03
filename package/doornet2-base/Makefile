include $(TOPDIR)/rules.mk

PKG_NAME:=doornet2-base
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/doornet2-base
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=DoorNet2 defaults, boot-source diagnostics and configuration policy
  DEPENDS:=+uci +dnsmasq-full
endef

define Package/doornet2-base/description
Non-disruptive DoorNet2 defaults. User-configured services and network
configuration remain under UCI control.
endef

define Build/Compile
endef

define Package/doornet2-base/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults $(1)/etc/doornet2 $(1)/usr/sbin $(1)/etc/init.d
	$(INSTALL_BIN) ./files/90-doornet2-policy $(1)/etc/uci-defaults/90-doornet2-policy
	$(INSTALL_DATA) ./files/wechatdirect.domains $(1)/etc/doornet2/wechatdirect.domains
	$(INSTALL_BIN) ./files/usr/sbin/doornet2-boot-report $(1)/usr/sbin/doornet2-boot-report
	$(INSTALL_BIN) ./files/etc/init.d/doornet2-boot-source $(1)/etc/init.d/doornet2-boot-source
endef

$(eval $(call BuildPackage,doornet2-base))
