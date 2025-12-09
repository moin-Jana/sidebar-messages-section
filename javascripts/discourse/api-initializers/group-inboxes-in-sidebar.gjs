import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import GroupInboxLink from "../lib/group-inbox-link";
import PersonalInboxLink from "../lib/personal-inbox-link";

export default apiInitializer((api) => {
  const currentUser = api.getCurrentUser();
  if (!currentUser) return;

  const router = api.container.lookup("service:router");
  const pmState = api.container.lookup("service:pm-topic-tracking-state");

  const useGroupPage = settings.group_inbox_type === "Group page";

class GroupPageInboxLink extends GroupInboxLink {
  constructor(currentUser, pmState, group) {
    super(currentUser, pmState, group);
    this.group = group;
  }

  // Use the group inbox route; Ember will generate the URL
  get route() {
    return "group.messages.inbox";
  }

  // Pass the group key (canonical URL segment is the group name)
  get models() {
    return [this.group.name];
  }

  // Keep the link highlighted across all group message tabs
  get currentWhen() {
    return "group.messages group.messages.inbox group.messages.sent group.messages.archive";
  }

}

  const showPersonalInbox = (() => {
    const mode = settings.show_personal_inbox;
    if (mode === "All users") return true;
    if (mode === "Nobody") return false;
    return currentUser.can_send_private_messages;
  })();

  const sidebarLinks = [];
  if (showPersonalInbox) {
    sidebarLinks.push(new PersonalInboxLink(currentUser, pmState));
  }

  const groups = currentUser.groupsWithMessages || [];
  const sortedGroups = groups.slice().sort((a, b) => a.id - b.id);
  const hidden = (settings.hide_group_inboxes || "").split("|").map(Number);

  for (const group of sortedGroups) {
    if (!hidden.includes(group.id)) {
      sidebarLinks.push(
        useGroupPage
          ? new GroupPageInboxLink(currentUser, pmState, group)
          : new GroupInboxLink(currentUser, pmState, group)
      );
    }
  }

  if (sidebarLinks.length > 0) {
    api.addSidebarSection((BaseCustomSidebarSection) => {
      return class InboxSection extends BaseCustomSidebarSection {
        name = "inbox-section";
        text = i18n(themePrefix("messages.title"));
        actionsIcon = "plus";

        get actions() {
          return [
            {
              id: "newPersonalMessage",
              title: i18n(themePrefix("messages.action")),
              action: () => router.transitionTo("new-message"),
            },
          ];
        }

        get links() {
          return sidebarLinks;
        }
      };
    }, "main");
  }
});
