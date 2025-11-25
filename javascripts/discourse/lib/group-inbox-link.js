import BaseCustomSidebarSectionLink from "discourse/lib/sidebar/base-custom-sidebar-section-link";
import { i18n } from "discourse-i18n";

export default class GroupInboxLink extends BaseCustomSidebarSectionLink {
  prefixType = "icon";
  prefixValue = "inbox";
  route = "userPrivateMessages.group";

  constructor(currentUser, pmState, group) {
    super();
    this.currentUser = currentUser;
    this.pmState = pmState;
    this.group = group;
  }

  get name() {
    return `group-inbox-${this.group.name}`;
  }

  get title() {
    return i18n(themePrefix("group_inbox.title"), {
      groupName: this.group.name,
    });
  }

  get text() {
    return this.group.name;
  }

  get models() {
    return [this.currentUser, this.group.name];
  }

  get unreadCount() {
    const pmState = this.pmState;
    if (!pmState?.states) {
      return (this._cachedCount = 0);
    }

    const groupName = this.group.name;

    const count =
      pmState.lookupCount("unread", {
        inboxFilter: "group",
        groupName,
      }) +
      pmState.lookupCount("new", {
        inboxFilter: "group",
        groupName,
      });

    return count;
  }

  get showDot() {
    return !this.currentUser.sidebarShowCountOfNewItems && this.unreadCount > 0;
  }

  get suffixType() {
    return this.showDot ? "icon" : "";
  }

  get suffixValue() {
    return this.showDot ? "circle" : "";
  }

  get suffixCSSClass() {
    return this.showDot ? "unread" : "";
  }

  get classNames() {
    if (this.showDot || this.unreadCount === 0) {
      return "";
    }

    if (this.unreadCount >= 100) {
      return "pm-inbox-count pm-inbox-count-99plus";
    }

    return `pm-inbox-count pm-inbox-count-${this.unreadCount}`;
  }
}
