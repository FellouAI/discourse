import { withPluginApi } from "discourse/lib/plugin-api";
import TopicActivityColumn from "../components/card/topic-activity-column";
import TopicCategoryColumn from "../components/card/topic-category-column";
import TopicCreatorColumn from "../components/card/topic-creator-column";
import TopicRepliesColumn from "../components/card/topic-replies-column";
import TopicStatusColumn from "../components/card/topic-status-column";

const TopicActivity = <template>
  <td class="topic-activity-data">
    <TopicActivityColumn @topic={{@topic}} />
  </td>
</template>;

const TopicStatus = <template>
  <td class="topic-status-data">
    <TopicStatusColumn @topic={{@topic}} />
  </td>
</template>;

const TopicCategory = <template>
  <td class="topic-category-data">
    <TopicCategoryColumn @topic={{@topic}} />
  </td>
</template>;

const TopicReplies = <template>
  <td class="topic-likes-replies-data">
    <TopicRepliesColumn @topic={{@topic}} />
  </td>
</template>;

const TopicCreator = <template>
  <td class="topic-creator-data">
    <TopicCreatorColumn @topic={{@topic}} />
  </td>
</template>;

export default {
  name: "topic-list-customizations",

  initialize(container) {
    const router = container.lookup("service:router");
    withPluginApi((api) => {
      api.registerValueTransformer(
        "topic-list-columns",
        ({ value: columns }) => {
          columns.add("topic-status", {
            item: TopicStatus,
            after: "topic-author",
          });
          columns.add("topic-category", {
            item: TopicCategory,
            after: "topic-status",
          });

          columns.add("topic-likes-replies", {
            item: TopicReplies,
            after: "topic-author-avatar",
          });
          columns.add("topic-creator", {
            item: TopicCreator,
            after: "topic-author-avatar",
          });
          columns.delete("views");
          columns.delete("replies");
          if (!router.currentRouteName.includes("userPrivateMessages")) {
            columns.add("topic-activity", {
              item: TopicActivity,
              after: "title",
            });
            columns.delete("posters");
            columns.delete("activity");
          }
          return columns;
        }
      );

      api.registerValueTransformer(
        "topic-list-item-class",
        ({ value: classes, context }) => {
          if (
            context.topic.is_hot ||
            context.topic.pinned ||
            context.topic.pinned_globally
          ) {
            classes.push("--has-status-card");
          }
          if (context.topic.replyCount > 1) {
            classes.push("has-replies");
          }
          return classes;
        }
      );

      api.registerValueTransformer("topic-list-item-mobile-layout", () => {
        return false;
      });

      api.registerBehaviorTransformer(
        "topic-list-item-click",
        ({ context: { event }, next }) => {
          if (event.target.closest("a, button, input")) {
            return next();
          }

          event.preventDefault();
          event.stopPropagation();

          // 尝试多种方式查找包装器
          let wrapper = event.target.closest(".topic-list-item-wrapper");

          // 如果找不到 wrapper，尝试查找父级的 topic-list-item
          if (!wrapper) {
            wrapper = event.target.closest(".topic-list-item");
          }

          // 如果还是找不到，尝试查找最近的 div 父元素
          if (!wrapper) {
            wrapper = event.target.closest("div");
          }

          // Debug: 记录查找结果
          console.warn("Click event target:", event.target);
          console.warn("Found wrapper:", wrapper);
          console.warn("Wrapper classList:", wrapper?.classList);

          if (!wrapper) {
            console.warn("Could not find any wrapper element");
            return next();
          }

          // 尝试多种方式查找链接
          let topicLink = wrapper.querySelector("a.raw-topic-link");

          // 如果找不到，尝试查找任何包含 topic 链接的 a 标签
          if (!topicLink) {
            topicLink = wrapper.querySelector("a[href*='/t/']");
          }

          // 如果还是找不到，尝试查找任何 a 标签
          if (!topicLink) {
            topicLink = wrapper.querySelector("a");
          }

          // Debug: 记录链接查找结果
          if (!topicLink) {
            console.warn("Could not find any link in wrapper:", wrapper);
            console.warn("Wrapper HTML:", wrapper.innerHTML);
            return next();
          }

          console.warn("Found topic link:", topicLink);

          // Redespatch the click on the topic link, so that all key-handing is sorted
          topicLink.dispatchEvent(
            new MouseEvent("click", {
              ctrlKey: event.ctrlKey,
              metaKey: event.metaKey,
              shiftKey: event.shiftKey,
              button: event.button,
              bubbles: true,
              cancelable: true,
            })
          );
        }
      );
    });
  },
};
